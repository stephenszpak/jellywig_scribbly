#!/bin/sh
# Xcode Cloud runs this right after checkout, before the build starts.
# Secrets.swift is gitignored (it holds the OpenAI API key), so it never
# exists in a fresh CI checkout. Regenerate it here from the OPENAI_API_KEY
# environment variable, which should be set as a *secret* in the Xcode
# Cloud workflow's Environment settings.
set -e

SECRETS_DIR="$CI_PRIMARY_REPOSITORY_PATH/Scribbly/App"
SECRETS_FILE="$SECRETS_DIR/Secrets.swift"

mkdir -p "$SECRETS_DIR"
cat > "$SECRETS_FILE" <<EOF
enum Secrets {
    static let openAIAPIKey = "${OPENAI_API_KEY:-}"
}
EOF

echo "Wrote $SECRETS_FILE"
