/**
 * Global art direction applied to every coloring page, regardless of
 * collection or difficulty. Keep this list additive/positive — negative
 * constraints ("no color", "no text", ...) live in negativeConstraints.ts
 * so the two can evolve independently and don't end up duplicated.
 */
export const baseStyleRules: string[] = [
  "children's coloring book page",
  "black outlines only",
  "pure white background",
  "clean, smooth, closed shapes",
  "bold, consistent outlines",
  "large colorable areas",
  "friendly, cute, non-threatening appearance",
  "centered composition",
  "full subject visible",
  "printable coloring-book aesthetic",
];

export function baseStyleBlock(): string {
  return baseStyleRules.join(", ");
}
