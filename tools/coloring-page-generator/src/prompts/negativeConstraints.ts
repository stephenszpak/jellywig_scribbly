/**
 * Things every prompt should tell the model to avoid. Centralized so a
 * single edit here updates every concept's prompt instead of hunting
 * through per-concept notes for near-duplicate phrasing.
 */
export const negativeConstraints: string[] = [
  "no color",
  "no grayscale",
  "no gray fills",
  "no shading",
  "no gradients",
  "no crosshatching",
  "no solid black filled regions unless absolutely necessary for tiny facial details",
  "no cropping",
  "no text",
  "no letters",
  "no numbers",
  "no watermark",
  "no decorative page border",
  "no overly detailed background",
  "no realistic anatomy",
  "no scary expressions",
  "no violence",
  "no clutter",
  "no overlapping outlines that make regions difficult to fill",
  "avoid photorealism",
  "avoid 3D rendering",
  "avoid sketchy pencil lines",
];

export function negativeConstraintsBlock(): string {
  return negativeConstraints.join(", ");
}
