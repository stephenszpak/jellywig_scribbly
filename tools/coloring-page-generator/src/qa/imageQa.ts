import type { ImageQaResult } from "../types.js";

/**
 * Placeholder for an automated image QA pass. Intended future checks:
 *  - accidental color present (should be pure black/white)
 *  - excessive detail relative to the concept's difficulty
 *  - cropped/off-center subject
 *  - stray text/letters/numbers baked into the image
 *  - gray fills or shading (vs. flat black-on-white)
 *  - whether region count/complexity actually matches the difficulty tier
 *
 * None of that is implemented yet — this always returns null so callers
 * (batchGenerator, metadata) can start threading a `qa` field through
 * without churn once a real checker (e.g. a vision-model pass, or a
 * pixel-histogram heuristic) lands here.
 */
export async function runImageQa(_imagePath: string): Promise<ImageQaResult | null> {
  return null;
}
