import path from "node:path";
import { generationConfig } from "../config/generationConfig.js";
import type { ColoringPageConcept } from "../types.js";

/** generated/<collection>/<difficulty>/<id>.png */
export function imageOutputPath(concept: ColoringPageConcept): string {
  return path.join(generationConfig.outputDir, concept.collection, concept.difficulty, `${concept.id}.png`);
}

/** generated/metadata/<id>.json */
export function metadataPath(concept: ColoringPageConcept): string {
  return path.join(generationConfig.outputDir, "metadata", `${concept.id}.json`);
}

/** generated/manifest.json */
export function manifestPath(): string {
  return path.join(generationConfig.outputDir, "manifest.json");
}
