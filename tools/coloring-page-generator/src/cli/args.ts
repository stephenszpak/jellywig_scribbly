export interface ParsedArgs {
  collection?: string;
  difficulty?: string;
  id?: string;
  all: boolean;
  force: boolean;
  dryRun: boolean;
  limit?: number;
}

/** Hand-rolled flag parsing — the flag set is small and fixed, so a
 * dependency like yargs/commander isn't worth the extra install. */
export function parseArgs(argv: string[]): ParsedArgs {
  const result: ParsedArgs = { all: false, force: false, dryRun: false };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--collection":
        result.collection = argv[++i];
        break;
      case "--difficulty":
        result.difficulty = argv[++i];
        break;
      case "--id":
        result.id = argv[++i];
        break;
      case "--all":
        result.all = true;
        break;
      case "--force":
        result.force = true;
        break;
      case "--dry-run":
        result.dryRun = true;
        break;
      case "--limit":
        result.limit = Number.parseInt(argv[++i] ?? "", 10);
        break;
      default:
        throw new Error(`Unknown flag "${arg}". See README for supported flags.`);
    }
  }

  return result;
}
