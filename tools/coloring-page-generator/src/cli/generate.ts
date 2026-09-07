#!/usr/bin/env node
import { concepts } from "../data/concepts.js";
import { validateConcepts } from "../validation/validateConcepts.js";
import { runBatch } from "../generation/batchGenerator.js";
import { parseArgs } from "./args.js";
import type { Difficulty } from "../types.js";

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  if (!args.collection && !args.id && !args.all) {
    console.error(
      "Nothing to generate — pass one of --collection <name>, --id <concept-id>, or --all.\n" +
        "Examples:\n" +
        "  npm run generate -- --collection dinosaur-land --difficulty simple\n" +
        "  npm run generate -- --id dinosaur-trex-wave-01\n" +
        "  npm run generate -- --all --dry-run"
    );
    process.exitCode = 1;
    return;
  }

  if (args.difficulty && args.difficulty !== "simple" && args.difficulty !== "intermediate") {
    console.error(`--difficulty must be "simple" or "intermediate", got "${args.difficulty}"`);
    process.exitCode = 1;
    return;
  }

  const errors = validateConcepts(concepts);
  if (errors.length > 0) {
    console.error("Concept data failed validation — fix these before generating:\n");
    for (const error of errors) console.error(`  [${error.id}] ${error.message}`);
    process.exitCode = 1;
    return;
  }

  const result = await runBatch(concepts, {
    collection: args.collection,
    difficulty: args.difficulty as Difficulty | undefined,
    id: args.id,
    all: args.all,
    force: args.force,
    dryRun: args.dryRun,
    limit: args.limit,
  });

  if (args.dryRun) {
    console.log(`\nDry run complete — ${result.outcomes.length} prompt(s) printed above, no images generated.`);
    return;
  }

  const generated = result.outcomes.filter((o) => o.status === "generated").length;
  const failed = result.outcomes.filter((o) => o.status === "failed").length;
  console.log(`\nDone: ${generated} generated, ${failed} failed, ${result.outcomes.length} attempted.`);
  if (failed > 0) {
    console.log(
      "Re-run the same command to retry the failed ones (already-generated pages are skipped automatically).\n" +
        "Use --force to also regenerate pages that already succeeded."
    );
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error("Unexpected error:", error);
  process.exitCode = 1;
});
