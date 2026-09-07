export type Difficulty = "simple" | "intermediate";

export type AgeRange = "3-5" | "5-7";

export interface ColoringPageConcept {
  id: string;
  collection: string;
  title: string;
  subject: string;
  scene?: string;
  difficulty: Difficulty;
  ageRange: AgeRange;
  supportingObjects?: string[];
  notes?: string;
}

export type GenerationStatus =
  | "pending"
  | "generating"
  | "generated"
  | "approved"
  | "rejected"
  | "failed";

export interface GenerationMetadata {
  id: string;
  collection: string;
  difficulty: Difficulty;
  title: string;
  prompt: string;
  promptVersion: string;
  generatedAt: string | null;
  model: string;
  size: string;
  status: GenerationStatus;
  outputFile: string | null;
  generationAttempt: number;
  lastError?: string;
  /** Reserved for a future automated image QA pass. Always null until that
   * exists — see src/qa/imageQa.ts for the placeholder interface. */
  qa?: ImageQaResult | null;
}

/**
 * Placeholder shape for an eventual automated QA pass over generated
 * artwork (color/shading/text/crop detection, difficulty match, etc).
 * Nothing implements this yet; `runImageQa` in src/qa/imageQa.ts always
 * returns `null` for now, but callers and metadata already carry the
 * field so wiring in a real checker later doesn't require a schema change.
 */
export interface ImageQaResult {
  checkedAt: string;
  passed: boolean;
  issues: string[];
}

export interface CollectionManifestEntry {
  id: string;
  title: string;
  outputFile: string;
}

export interface GeneratedManifest {
  collections: Record<string, Record<Difficulty, CollectionManifestEntry[]>>;
}
