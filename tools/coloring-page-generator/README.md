# Coloring Page Generator

Internal developer tool for batch-generating Scribbly's black-and-white
coloring page artwork via OpenAI's Images API. Not part of the iOS app —
this runs on a developer's machine to produce PNGs + metadata that later
get bundled into (or synced with) the app.

## Setup

```bash
cd tools/coloring-page-generator
npm install
cp .env.example .env
# then edit .env and set OPENAI_API_KEY
```

Requires Node 20+ (uses `process.loadEnvFile`, no `dotenv` dependency).

## Environment variables

Set in `.env` (gitignored — never commit real keys):

| Variable | Default | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | *(required)* | Your OpenAI API key. Never hardcoded. |
| `COLORING_GEN_MODEL` | `gpt-image-1` | Image model (matches the iOS app's own generator). |
| `COLORING_GEN_SIZE` | `1024x1024` | Output image size. |
| `COLORING_GEN_QUALITY` | `low` | gpt-image-1 quality tier: low / medium / high / auto. |
| `COLORING_GEN_PROMPT_VERSION` | `1.0` | Stamped into metadata; bump when you change prompt structure. |
| `COLORING_GEN_CONCURRENCY` | `2` | Parallel in-flight image requests. |
| `COLORING_GEN_DELAY_MS` | `500` | Delay before each request (per concurrency slot). |
| `COLORING_GEN_MAX_RETRIES` | `3` | Retries for transient failures (429 / 5xx / network). |
| `COLORING_GEN_RETRY_BASE_MS` | `1000` | Base delay for exponential backoff between retries. |
| `COLORING_GEN_OUTPUT_DIR` | `generated` | Where images/metadata/manifest are written. |

All of these live in `src/config/generationConfig.ts` — that's the single
place to change defaults; nothing else in the codebase should hardcode
model names, sizes, concurrency, etc.

## Concept data model

Every coloring page is defined as structured data in `src/data/concepts.ts`,
not as a hand-written prompt:

```ts
type ColoringPageConcept = {
  id: string;              // unique, filename-safe: lowercase + hyphens
  collection: string;      // groups concepts, e.g. "dinosaur-land"
  title: string;           // human-readable title
  subject: string;         // what's drawn — fed into the prompt
  scene?: string;          // optional environment/background description
  difficulty: "simple" | "intermediate";
  ageRange: "3-5" | "5-7";
  supportingObjects?: string[];
  notes?: string;          // concept-specific prompt notes
};
```

### How to add a concept

Open `src/data/concepts.ts` and append an object to the `concepts` array
with a new, unique `id`. Run `npm run validate-concepts` afterward — it
checks required fields, valid `difficulty`/`ageRange` values, filename-safe
ids, and duplicate ids, without calling the image API.

### How to add a collection

There's no separate collection registry to update — a "collection" is
just whatever string you put in a concept's `collection` field. Add
concepts with a new `collection` value and it shows up automatically in
file output (`generated/<collection>/...`) and the manifest.

## Prompt construction

`src/prompts/promptBuilder.ts` exports `buildColoringPagePrompt(concept)`,
which combines, in order:

1. The concept's `subject` (and `scene`, `supportingObjects` if present)
2. Global art-direction rules (`src/prompts/baseStyle.ts`) — black
   outlines, white background, no shading, friendly/centered composition,
   etc. — shared by every concept.
3. Difficulty-specific composition rules (`src/prompts/difficultyRules.ts`)
   — simple vs. intermediate region count, background detail, subject
   count.
4. The concept's free-form `notes`, if any.
5. Negative constraints (`src/prompts/negativeConstraints.ts`) — no color,
   no text, no cropping, no clutter, etc.

None of that shared text is duplicated per concept — concepts only ever
contain their own subject/scene/notes.

## Generating images

```bash
# One specific concept
npm run generate -- --id dinosaur-trex-wave-01

# A whole collection
npm run generate -- --collection dinosaur-land

# One difficulty within a collection
npm run generate -- --collection dinosaur-land --difficulty simple

# Every pending concept across all collections
npm run generate -- --all

# See prompts without calling the API or spending money
npm run generate -- --all --dry-run

# Cap how many concepts are processed in one run
npm run generate -- --all --limit 5

# Regenerate even concepts that already succeeded
npm run generate -- --collection dinosaur-land --force
```

At least one of `--collection`, `--id`, or `--all` is required, so you
never accidentally regenerate everything.

### Retrying failures

Failed concepts are marked `"status": "failed"` in their metadata file
and are **automatically retried** on the next plain run of the same
filters — only concepts already `"generated"` or `"approved"` are skipped.
So after a batch with some failures:

```bash
npm run generate -- --collection dinosaur-land
```

...will only re-attempt the ones that failed (or were never generated).
Use `--force` only when you want to redo pages that already succeeded
(e.g. after a prompt/style change).

A single failed image never aborts the batch — every other concept still
gets processed, and failures are printed clearly at the end.

## Where outputs are saved

```
generated/
  <collection>/
    simple/
      <concept-id>.png
    intermediate/
      <concept-id>.png
  metadata/
    <concept-id>.json
  manifest.json
```

`generated/` is gitignored — these are build artifacts, not source. Check
in the *concepts*, regenerate the images.

## How metadata works

Every concept gets a `generated/metadata/<id>.json` file, written *before*
the API call (status `"generating"`) and updated after it resolves
(`"generated"` or `"failed"`):

```json
{
  "id": "dinosaur-trex-wave-01",
  "collection": "dinosaur-land",
  "difficulty": "simple",
  "title": "Happy T-Rex Waving",
  "prompt": "...",
  "promptVersion": "1.0",
  "generatedAt": "2025-01-01T12:00:00.000Z",
  "model": "gpt-image-1",
  "size": "1024x1024",
  "status": "generated",
  "outputFile": "generated/dinosaur-land/simple/dinosaur-trex-wave-01.png",
  "generationAttempt": 1,
  "qa": null
}
```

`status` is one of `pending | generating | generated | approved | rejected | failed`.
There's no concept of "pending" metadata file — a concept with no metadata
file yet is implicitly pending. To **approve** or **reject** an image
after reviewing it by eye, hand-edit its metadata file's `status` field
(or build a small script against `src/generation/metadata.ts` if you want
a CLI for it later) — only `"generated"` and `"approved"` pages are ever
included in `manifest.json`.

`generated/manifest.json` is rebuilt after every non-dry-run batch from
whatever metadata currently has status `generated`/`approved`:

```json
{
  "collections": {
    "dinosaur-land": {
      "simple": [{ "id": "...", "title": "...", "outputFile": "..." }],
      "intermediate": [...]
    }
  }
}
```

That's the file meant for eventual consumption by the app (or a script
that copies approved assets into the app bundle).

## Image QA (placeholder)

`src/qa/imageQa.ts` exports `runImageQa(imagePath)`, which always returns
`null` today. It's there so a future automated check — detecting stray
color, text, shading, cropping, or a region-count/difficulty mismatch —
has a clean seam to plug into (`GenerationMetadata.qa`) without a schema
migration. Nothing currently calls it from the batch pipeline.

## Flags reference

| Flag | Purpose |
|---|---|
| `--collection <name>` | Only concepts in this collection |
| `--difficulty <simple\|intermediate>` | Only concepts at this difficulty |
| `--id <concept-id>` | Only this one concept |
| `--all` | Every concept (still filterable by the flags above) |
| `--force` | Also regenerate concepts already `generated`/`approved` |
| `--dry-run` | Print prompts, make no API calls, write no files |
| `--limit <n>` | Cap how many concepts this run processes |
