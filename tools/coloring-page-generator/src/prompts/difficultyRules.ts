import type { Difficulty } from "../types.js";

/**
 * Difficulty-specific composition rules. These are the only place
 * "simple" vs "intermediate" behavior should be defined — concepts just
 * pick a difficulty, they never restate these rules themselves.
 */
const difficultyRules: Record<Difficulty, string[]> = {
  simple: [
    "intended for ages 3-5",
    "one primary subject",
    "maximum of two simple supporting objects",
    "minimal or no background",
    "very large enclosed coloring regions",
    "very few tiny details",
    "simple facial features",
    "thick outlines",
    "approximately 10-25 distinct colorable regions",
    "composition should remain easy to color with a finger on an iPad",
  ],
  intermediate: [
    "intended for ages 5-7",
    "one to four main subjects",
    "simple environmental scene allowed",
    "moderate amount of background detail",
    "still maintain large clear enclosed regions",
    "moderate detail but never intricate adult-coloring-book detail",
    "avoid dense textures and tiny repeating patterns",
    "approximately 30-60 distinct colorable regions",
    "suitable for finger or stylus coloring on an iPad",
  ],
};

export function difficultyBlock(difficulty: Difficulty): string {
  return difficultyRules[difficulty].join(", ");
}
