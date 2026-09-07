import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Side-effect-only module: loads .env (if present) into process.env using
 * Node's built-in loader, so nothing here depends on the "dotenv" package.
 * Safe to import even when .env doesn't exist yet (e.g. CI, validate-only
 * runs) — it just silently does nothing in that case.
 */
const here = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.join(here, "..", "..", ".env");

if (existsSync(envPath) && typeof process.loadEnvFile === "function") {
  process.loadEnvFile(envPath);
}
