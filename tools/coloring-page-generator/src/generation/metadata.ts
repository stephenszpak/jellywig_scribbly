import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import type { GenerationMetadata } from "../types.js";
import { metadataPath } from "./fileNaming.js";

export async function readMetadata(conceptId: string, filePath: string): Promise<GenerationMetadata | null> {
  try {
    const raw = await readFile(filePath, "utf8");
    return JSON.parse(raw) as GenerationMetadata;
  } catch (error) {
    if (isNotFound(error)) return null;
    throw new Error(`Couldn't read metadata for "${conceptId}": ${String(error)}`);
  }
}

export async function writeMetadata(metadata: GenerationMetadata, filePath: string): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(metadata, null, 2) + "\n", "utf8");
}

export async function loadAllMetadata(outputDir: string): Promise<GenerationMetadata[]> {
  const { readdir } = await import("node:fs/promises");
  const dir = path.join(outputDir, "metadata");
  let files: string[];
  try {
    files = await readdir(dir);
  } catch (error) {
    if (isNotFound(error)) return [];
    throw error;
  }
  const results: GenerationMetadata[] = [];
  for (const file of files) {
    if (!file.endsWith(".json")) continue;
    const raw = await readFile(path.join(dir, file), "utf8");
    results.push(JSON.parse(raw) as GenerationMetadata);
  }
  return results;
}

function isNotFound(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && (error as { code?: string }).code === "ENOENT";
}

export { metadataPath };
