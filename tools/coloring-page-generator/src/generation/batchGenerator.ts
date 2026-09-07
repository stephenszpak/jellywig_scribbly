import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import type { ColoringPageConcept, Difficulty, GenerationMetadata } from "../types.js";
import { generationConfig } from "../config/generationConfig.js";
import { buildColoringPagePrompt } from "../prompts/promptBuilder.js";
import { generateImageBuffer, ImageGenerationError } from "../services/imageGenerator.js";
import { imageOutputPath, metadataPath } from "./fileNaming.js";
import { readMetadata, writeMetadata } from "./metadata.js";
import { rebuildManifest } from "./manifest.js";

export interface BatchOptions {
  collection?: string;
  difficulty?: Difficulty;
  id?: string;
  all?: boolean;
  force?: boolean;
  dryRun?: boolean;
  limit?: number;
}

export interface BatchOutcome {
  id: string;
  status: "generated" | "skipped" | "failed" | "dry-run";
  detail?: string;
}

export interface BatchResult {
  outcomes: BatchOutcome[];
}

/**
 * Applies --collection / --difficulty / --id / --limit filters. Concepts
 * that were previously generated or approved are excluded unless --force
 * is passed, so a plain re-run only picks up pending/failed work.
 */
export function selectConcepts(
  concepts: ColoringPageConcept[],
  options: BatchOptions,
  previousStatus: Map<string, GenerationMetadata>
): ColoringPageConcept[] {
  let selected = concepts;

  if (options.id) {
    selected = selected.filter((c) => c.id === options.id);
  }
  if (options.collection) {
    selected = selected.filter((c) => c.collection === options.collection);
  }
  if (options.difficulty) {
    selected = selected.filter((c) => c.difficulty === options.difficulty);
  }

  if (!options.force) {
    selected = selected.filter((c) => {
      const previous = previousStatus.get(c.id);
      return !previous || (previous.status !== "generated" && previous.status !== "approved");
    });
  }

  if (options.limit && options.limit > 0) {
    selected = selected.slice(0, options.limit);
  }

  return selected;
}

export async function runBatch(concepts: ColoringPageConcept[], options: BatchOptions): Promise<BatchResult> {
  const previousStatus = new Map<string, GenerationMetadata>();
  for (const concept of concepts) {
    const existing = await readMetadata(concept.id, metadataPath(concept));
    if (existing) previousStatus.set(concept.id, existing);
  }

  const selected = selectConcepts(concepts, options, previousStatus);
  const outcomes: BatchOutcome[] = [];

  if (selected.length === 0) {
    console.log("No concepts matched the given filters (or everything is already generated — pass --force to redo).");
    return { outcomes };
  }

  await runWithConcurrency(selected, generationConfig.concurrency, async (concept) => {
    const outcome = await processConcept(concept, options, previousStatus.get(concept.id));
    outcomes.push(outcome);
    logOutcome(outcome, concept);
  });

  if (!options.dryRun) {
    await rebuildManifest();
  }

  return { outcomes };
}

async function processConcept(
  concept: ColoringPageConcept,
  options: BatchOptions,
  previous: GenerationMetadata | undefined
): Promise<BatchOutcome> {
  const prompt = buildColoringPagePrompt(concept);

  if (options.dryRun) {
    console.log(`\n--- ${concept.id} (${concept.collection}/${concept.difficulty}) ---`);
    console.log(prompt);
    return { id: concept.id, status: "dry-run" };
  }

  const attempt = (previous?.generationAttempt ?? 0) + 1;
  const imagePath = imageOutputPath(concept);
  const metaPath = metadataPath(concept);

  await writeMetadata(
    buildMetadata(concept, prompt, "generating", { attempt, outputFile: previous?.outputFile ?? null }),
    metaPath
  );

  if (generationConfig.delayBetweenRequestsMs > 0) {
    await sleep(generationConfig.delayBetweenRequestsMs);
  }

  try {
    const buffer = await generateImageBuffer(prompt);
    await mkdir(path.dirname(imagePath), { recursive: true });
    await writeFile(imagePath, buffer);

    await writeMetadata(
      buildMetadata(concept, prompt, "generated", { attempt, outputFile: imagePath, generatedAt: new Date().toISOString() }),
      metaPath
    );
    return { id: concept.id, status: "generated" };
  } catch (error) {
    const message = error instanceof ImageGenerationError ? error.message : String(error);
    await writeMetadata(
      buildMetadata(concept, prompt, "failed", { attempt, outputFile: previous?.outputFile ?? null, lastError: message }),
      metaPath
    );
    return { id: concept.id, status: "failed", detail: message };
  }
}

function buildMetadata(
  concept: ColoringPageConcept,
  prompt: string,
  status: GenerationMetadata["status"],
  extra: { attempt: number; outputFile: string | null; generatedAt?: string; lastError?: string }
): GenerationMetadata {
  return {
    id: concept.id,
    collection: concept.collection,
    difficulty: concept.difficulty,
    title: concept.title,
    prompt,
    promptVersion: generationConfig.promptVersion,
    generatedAt: extra.generatedAt ?? null,
    model: generationConfig.model,
    size: generationConfig.imageSize,
    status,
    outputFile: extra.outputFile,
    generationAttempt: extra.attempt,
    lastError: extra.lastError,
    qa: null,
  };
}

function logOutcome(outcome: BatchOutcome, concept: ColoringPageConcept): void {
  switch (outcome.status) {
    case "generated":
      console.log(`✅ generated  ${concept.id}`);
      break;
    case "skipped":
      console.log(`⏭️  skipped   ${concept.id}`);
      break;
    case "failed":
      console.error(`❌ failed    ${concept.id} — ${outcome.detail}`);
      break;
    case "dry-run":
      break; // prompt already printed
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Minimal concurrency-limited runner — avoids pulling in a dependency
 * (e.g. p-limit) for something this small. */
async function runWithConcurrency<T>(items: T[], limit: number, worker: (item: T) => Promise<void>): Promise<void> {
  let cursor = 0;
  const workers = Array.from({ length: Math.max(1, Math.min(limit, items.length)) }, async () => {
    while (cursor < items.length) {
      const index = cursor;
      cursor += 1;
      const item = items[index];
      if (item === undefined) continue;
      await worker(item);
    }
  });
  await Promise.all(workers);
}
