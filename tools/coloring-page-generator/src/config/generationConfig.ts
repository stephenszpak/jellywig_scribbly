import "./loadEnv.js";

/**
 * Centralized, environment-overridable generation settings. Nothing in
 * services/ or generation/ should hardcode these values directly — change
 * behavior here (or via env vars) instead of scattering constants.
 */

function envString(name: string, fallback: string): string {
  const value = process.env[name];
  return value && value.trim().length > 0 ? value.trim() : fallback;
}

function envInt(name: string, fallback: number): number {
  const value = process.env[name];
  if (!value) return fallback;
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export const generationConfig = {
  /** OpenAI model used for image generation. Matches the iOS app's own
   * OpenAIImageGenerator.swift, which uses gpt-image-1 since dall-e-3 is
   * no longer available via the Images API. */
  model: envString("COLORING_GEN_MODEL", "gpt-image-1"),

  /** Square output size passed to the Images API. */
  imageSize: envString("COLORING_GEN_SIZE", "1024x1024"),

  /** gpt-image-1 quality tier: low | medium | high | auto. */
  quality: envString("COLORING_GEN_QUALITY", "low"),

  /** Bumping this invalidates cached/previous prompts for diffing —
   * stamped into every metadata file so you can tell which prompt
   * generation an asset came from. */
  promptVersion: envString("COLORING_GEN_PROMPT_VERSION", "1.0"),

  /** How many image requests run in parallel. Kept conservative by
   * default to avoid tripping OpenAI rate limits. */
  concurrency: envInt("COLORING_GEN_CONCURRENCY", 2),

  /** Minimum delay (ms) between requests *within* a concurrency slot. */
  delayBetweenRequestsMs: envInt("COLORING_GEN_DELAY_MS", 500),

  /** Retries for transient failures (network errors, 429, 5xx). */
  maxRetries: envInt("COLORING_GEN_MAX_RETRIES", 3),

  /** Base delay for exponential backoff between retries. */
  retryBaseDelayMs: envInt("COLORING_GEN_RETRY_BASE_MS", 1000),

  /** Root output directory for generated images + metadata + manifest. */
  outputDir: envString("COLORING_GEN_OUTPUT_DIR", "generated"),
} as const;

export const openAIApiKey = process.env.OPENAI_API_KEY ?? "";
