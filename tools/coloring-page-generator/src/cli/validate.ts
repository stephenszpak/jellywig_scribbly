#!/usr/bin/env node
import { concepts } from "../data/concepts.js";
import { validateConcepts } from "../validation/validateConcepts.js";

function main(): void {
  const errors = validateConcepts(concepts);

  console.log(`Checked ${concepts.length} concept(s) across ${new Set(concepts.map((c) => c.collection)).size} collection(s).`);

  if (errors.length === 0) {
    console.log("✅ All concepts are valid.");
    return;
  }

  console.error(`\n❌ Found ${errors.length} problem(s):\n`);
  for (const error of errors) {
    console.error(`  [${error.id}] ${error.message}`);
  }
  process.exitCode = 1;
}

main();
