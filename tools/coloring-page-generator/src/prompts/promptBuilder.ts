import type { ColoringPageConcept } from "../types.js";
import { baseStyleBlock } from "./baseStyle.js";
import { difficultyBlock } from "./difficultyRules.js";
import { negativeConstraintsBlock } from "./negativeConstraints.js";

/**
 * Turns a structured concept into the final text prompt sent to the
 * image API. This is the ONLY place concept fields get woven into prose —
 * concepts themselves stay pure data, and the global style/difficulty/
 * negative-constraint text lives in their own modules so it's never
 * duplicated per concept.
 */
export function buildColoringPagePrompt(concept: ColoringPageConcept): string {
  const sections: string[] = [];

  sections.push(subjectDescription(concept));

  if (concept.scene) {
    sections.push(`Scene: ${concept.scene}.`);
  }

  if (concept.supportingObjects && concept.supportingObjects.length > 0) {
    sections.push(`Include: ${concept.supportingObjects.join(", ")}.`);
  }

  sections.push(`Style: ${baseStyleBlock()}.`);
  sections.push(`Difficulty guidance: ${difficultyBlock(concept.difficulty)}.`);

  if (concept.notes) {
    sections.push(`Additional notes: ${concept.notes}.`);
  }

  sections.push(`Avoid: ${negativeConstraintsBlock()}.`);

  return sections.join(" ");
}

function subjectDescription(concept: ColoringPageConcept): string {
  return `A children's coloring book page of ${concept.subject}.`;
}
