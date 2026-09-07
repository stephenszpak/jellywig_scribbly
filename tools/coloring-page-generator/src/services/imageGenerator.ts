import { generationConfig, openAIApiKey } from "../config/generationConfig.js";

export class ImageGenerationError extends Error {
  constructor(message: string, readonly retryable: boolean) {
    super(message);
    this.name = "ImageGenerationError";
  }
}

interface OpenAIImageResponse {
  data: { b64_json: string }[];
}

interface OpenAIErrorResponse {
  error?: { message?: string };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Calls OpenAI's Images API for a single prompt and returns raw PNG
 * bytes. Retries transient failures (network errors, 429, 5xx) with
 * exponential backoff; non-transient failures (bad request, auth) throw
 * immediately since retrying won't help.
 */
export async function generateImageBuffer(prompt: string): Promise<Buffer> {
  if (!openAIApiKey) {
    throw new ImageGenerationError(
      "OPENAI_API_KEY is not set. Copy .env.example to .env and add your key.",
      false
    );
  }

  let attempt = 0;
  let lastError: ImageGenerationError | null = null;

  while (attempt < generationConfig.maxRetries) {
    attempt += 1;
    try {
      return await requestImage(prompt);
    } catch (error) {
      const wrapped = error instanceof ImageGenerationError ? error : new ImageGenerationError(String(error), true);
      lastError = wrapped;
      if (!wrapped.retryable || attempt >= generationConfig.maxRetries) {
        throw wrapped;
      }
      const backoff = generationConfig.retryBaseDelayMs * 2 ** (attempt - 1);
      await sleep(backoff);
    }
  }

  throw lastError ?? new ImageGenerationError("Image generation failed for an unknown reason.", false);
}

async function requestImage(prompt: string): Promise<Buffer> {
  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/images/generations", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAIApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: generationConfig.model,
        prompt,
        size: generationConfig.imageSize,
        quality: generationConfig.quality,
        n: 1,
      }),
    });
  } catch (networkError) {
    throw new ImageGenerationError(`Network error calling OpenAI: ${String(networkError)}`, true);
  }

  if (!response.ok) {
    const retryable = response.status === 429 || response.status >= 500;
    let message = `OpenAI API returned ${response.status}`;
    try {
      const body = (await response.json()) as OpenAIErrorResponse;
      if (body.error?.message) message = body.error.message;
    } catch {
      // ignore body parse failure, fall back to the status-based message
    }
    throw new ImageGenerationError(message, retryable);
  }

  let parsed: OpenAIImageResponse;
  try {
    parsed = (await response.json()) as OpenAIImageResponse;
  } catch {
    throw new ImageGenerationError("Couldn't parse OpenAI response as JSON.", true);
  }

  const b64 = parsed.data?.[0]?.b64_json;
  if (!b64) {
    throw new ImageGenerationError("OpenAI response did not include image data.", true);
  }

  return Buffer.from(b64, "base64");
}
