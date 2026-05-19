#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

JAR_VERSION="2.0.11"
JAR_NAME="sparql-examples-utils-${JAR_VERSION}-uber.jar"
JAR_PATH="target/${JAR_NAME}"
JAR_URL="https://github.com/sib-swiss/sparql-examples-utils/releases/download/v${JAR_VERSION}/${JAR_NAME}"
NEXTPROT_ENDPOINT="https://sparql.nextprot.org/sparql"

IGNORE_ENDPOINTS=()

usage() {
  cat <<'EOF'
Usage: ./update-and-extract.sh [options]

Options:
  -i, --ignore-endpoint <endpoint>  Exclude queries targeting/federating with endpoint (repeatable)
      --ignore-nextprot             Shortcut for --ignore-endpoint https://sparql.nextprot.org/sparql
  -h, --help                        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ignore-endpoint)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1" >&2
        usage
        exit 1
      fi
      IGNORE_ENDPOINTS+=("$2")
      shift 2
      ;;
    --ignore-nextprot)
      IGNORE_ENDPOINTS+=("$NEXTPROT_ENDPOINT")
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

echo "Updating sparql-examples submodule to latest upstream..."
git submodule update --init --remote

mkdir -p target
if [[ ! -f "$JAR_PATH" ]]; then
  echo "Downloading converter JAR ${JAR_NAME}..."
  if command -v wget >/dev/null 2>&1; then
    wget "$JAR_URL" -O "$JAR_PATH"
  elif command -v curl >/dev/null 2>&1; then
    curl -L "$JAR_URL" -o "$JAR_PATH"
  else
    echo "Need either wget or curl to download ${JAR_NAME}" >&2
    exit 1
  fi
fi

echo "Regenerating all_queries.ttl from latest examples..."
java -jar "$JAR_PATH" convert -i sib-swiss-query-examples/examples/ -p all -f ttl > all_queries.ttl

if command -v corepack >/dev/null 2>&1; then
  export COREPACK_HOME="${COREPACK_HOME:-${ROOT_DIR}/.corepack-cache}"
  mkdir -p "$COREPACK_HOME"
  YARN_CMD=(corepack yarn)
else
  YARN_CMD=(yarn)
fi

echo "Installing JS dependencies..."
"${YARN_CMD[@]}" install

EXTRACT_ARGS=(node index.mjs)
if [[ ${#IGNORE_ENDPOINTS[@]} -gt 0 ]]; then
  EXTRACT_ARGS+=(--ignoreEndpoints "${IGNORE_ENDPOINTS[@]}")
fi

echo "Extracting federated queries..."
"${YARN_CMD[@]}" "${EXTRACT_ARGS[@]}"

echo "Done. Output written to sib-swiss-federated-queries.json"
