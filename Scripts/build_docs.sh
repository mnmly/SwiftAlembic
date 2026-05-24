#!/usr/bin/env bash
# Build the static DocC site for SwiftAlembic into ./docs (GitHub Pages-ready).
#
# Usage:
#   Scripts/build_docs.sh                # build docs/SwiftAlembic/
#   Scripts/build_docs.sh preview        # local preview
#   Scripts/build_docs.sh -f             # bypass gh-pages branch guard
set -euo pipefail

cd "$(dirname "$0")/.."

TARGETS="${TARGETS:-SwiftAlembic}"
HOSTING_BASE_PATH="${HOSTING_BASE_PATH:-SwiftAlembic}"
REPO_URL="${REPO_URL:-https://github.com/mnmly/SwiftAlembic}"
REPO_BRANCH="${REPO_BRANCH:-main}"
OUTPUT_DIR="${OUTPUT_DIR:-docs}"

FORCE=0
MODE="build"
for arg in "$@"; do
    case "$arg" in
        -f|--force) FORCE=1 ;;
        preview)    MODE="preview" ;;
    esac
done

if [[ "${REQUIRE_GH_PAGES:-0}" == "1" && "$MODE" == "build" && $FORCE -eq 0 ]]; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo)"
    if [[ "$branch" != "gh-pages" ]]; then
        echo "Refusing to build off branch '$branch'. Use -f to override."
        exit 1
    fi
fi

export DOCC_JSON_PRETTYPRINT=YES

if [[ "$MODE" == "preview" ]]; then
    first_target="${TARGETS%% *}"
    exec swift package --disable-sandbox \
        preview-documentation --target "$first_target"
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

EXTRA_FLAGS=()
if [[ "${EMIT_MARKDOWN:-0}" == "1" || "${EMIT_LLMS_TXT:-0}" == "1" ]]; then
    EXTRA_FLAGS+=(--enable-experimental-markdown-output)
fi

SOURCE_FLAGS=()
if [[ -n "$REPO_URL" ]]; then
    SOURCE_FLAGS+=(
        --source-service github
        --source-service-base-url "${REPO_URL%/}/blob/${REPO_BRANCH}"
        --checkout-path "$(pwd)"
    )
fi

for TARGET in $TARGETS; do
    slug="$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')"
    out="$OUTPUT_DIR/$TARGET"
    mkdir -p "$out"

    echo ">> Building DocC for $TARGET → $out"
    swift package --allow-writing-to-directory "$out" \
        generate-documentation \
        --target "$TARGET" \
        --fallback-bundle-identifier "${HOSTING_BASE_PATH}.${slug}" \
        --output-path "$out" \
        --emit-digest \
        --disable-indexing \
        --transform-for-static-hosting \
        --hosting-base-path "${HOSTING_BASE_PATH}/${TARGET}" \
        ${SOURCE_FLAGS[@]+"${SOURCE_FLAGS[@]}"} \
        ${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}
done

if [[ "${EMIT_LLMS_TXT:-0}" == "1" ]]; then
    LLMS="$OUTPUT_DIR/llms.txt"
    {
        echo "# ${HOSTING_BASE_PATH} — DocC export for LLM consumption"
        echo
        echo "Generated $(date -u +%FT%TZ) from swift-docc."
        echo "Targets: $TARGETS"
        echo
        for TARGET in $TARGETS; do
            find "$OUTPUT_DIR/$TARGET/data" -name '*.md' -type f 2>/dev/null \
                | sort \
                | while IFS= read -r f; do
                    rel="${f#$OUTPUT_DIR/}"
                    echo
                    echo "---"
                    echo "## $rel"
                    echo
                    cat "$f"
                done
        done
    } > "$LLMS"
    echo "Wrote $LLMS ($(wc -l < "$LLMS" | tr -d ' ') lines)."
fi

# Tiny landing page that redirects to the SwiftAlembic target docs so
# https://mnmly.github.io/SwiftAlembic/ lands on the module page.
cat > "$OUTPUT_DIR/index.html" <<HTML
<!doctype html>
<meta charset="utf-8">
<title>SwiftAlembic</title>
<meta http-equiv="refresh" content="0; url=./SwiftAlembic/documentation/swiftalembic/">
<link rel="canonical" href="./SwiftAlembic/documentation/swiftalembic/">
<p>Redirecting to <a href="./SwiftAlembic/documentation/swiftalembic/">SwiftAlembic documentation</a>.</p>
HTML

echo
echo "Docs written to $OUTPUT_DIR/. Open $OUTPUT_DIR/SwiftAlembic/index.html"
echo "or push to gh-pages."
