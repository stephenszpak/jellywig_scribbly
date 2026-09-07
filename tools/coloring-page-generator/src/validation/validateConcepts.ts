import type { ColoringPageConcept, Difficulty, AgeRange } from "../types.js";

export interface ConceptValidationError {
  id: string;
  message: string;
}

const VALID_DIFFICULTIES: Difficulty[] = ["simple", "intermediate"];
const VALID_AGE_RANGES: AgeRange[] = ["3-5", "5-7"];

/** Filenames are derived directly from concept ids (see fileNaming.ts),
 * so ids must be safe as a bare path segment on every OS we care about. */
const SAFE_FILENAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/**
 * Validates the full concept list: required fields, unique ids, valid
 * enum values, and filename-safe ids. Pure function, no I/O — the CLI
 * layer decides how to report results.
 */
export function validateConcepts(concepts: ColoringPageConcept[]): ConceptValidationError[] {
  const errors: ConceptValidationError[] = [];
  const seenIds = new Map<string, number>();

  concepts.forEach((concept, index) => {
    const label = concept.id || `#${index} (missing id)`;

    for (const field of ["id", "title", "subject", "collection", "difficulty", "ageRange"] as const) {
      const value = concept[field];
      if (value === undefined || value === null || String(value).trim().length === 0) {
        errors.push({ id: label, message: `missing required field "${field}"` });
      }
    }

    if (concept.id) {
      seenIds.set(concept.id, (seenIds.get(concept.id) ?? 0) + 1);
      if (!SAFE_FILENAME_PATTERN.test(concept.id)) {
        errors.push({
          id: concept.id,
          message: `id "${concept.id}" is not filename-safe (use lowercase letters, digits, and single hyphens only)`,
        });
      }
    }

    if (concept.difficulty && !VALID_DIFFICULTIES.includes(concept.difficulty)) {
      errors.push({ id: label, message: `invalid difficulty "${concept.difficulty}"` });
    }

    if (concept.ageRange && !VALID_AGE_RANGES.includes(concept.ageRange)) {
      errors.push({ id: label, message: `invalid ageRange "${concept.ageRange}"` });
    }
  });

  for (const [id, count] of seenIds) {
    if (count > 1) {
      errors.push({ id, message: `duplicate id used by ${count} concepts` });
    }
  }

  return errors;
}
