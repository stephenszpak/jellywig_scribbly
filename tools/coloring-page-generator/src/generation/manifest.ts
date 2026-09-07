import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import type { Difficulty, GeneratedManifest } from "../types.js";
import { generationConfig } from "../config/generationConfig.js";
import { loadAllMetadata } from "./metadata.js";
import { manifestPath } from "./fileNaming.js";

/**
 * Rebuilds generated/manifest.json from every metadata file on disk,
 * including only assets that are actually ready to consume (status
 * "generated" or "approved" — never "pending", "failed", or "rejected").
 * Intended to be the eventual hand-off point for the coloring app.
 */
export async function rebuildManifest(): Promise<GeneratedManifest> {
  const allMetadata = await loadAllMetadata(generationConfig.outputDir);
  const manifest: GeneratedManifest = { collections: {} };

  for (const entry of allMetadata) {
    if (entry.status !== "generated" && entry.status !== "approved") continue;
    if (!entry.outputFile) continue;

    const byCollection = (manifest.collections[entry.collection] ??= {
      simple: [],
      intermediate: [],
    } as Record<Difficulty, typeof manifest.collections[string]["simple"]>);

    byCollection[entry.difficulty].push({
      id: entry.id,
      title: entry.title,
      outputFile: entry.outputFile,
    });
  }

  const filePath = manifestPath();
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, JSON.stringify(manifest, null, 2) + "\n", "utf8");
  return manifest;
}
