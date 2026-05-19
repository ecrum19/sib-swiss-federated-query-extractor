#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

JAR_VERSION="2.0.11"
JAR_NAME="sparql-examples-utils-${JAR_VERSION}-uber.jar"
JAR_PATH="target/${JAR_NAME}"
JAR_URL="https://github.com/sib-swiss/sparql-examples-utils/releases/download/v${JAR_VERSION}/${JAR_NAME}"

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
  export COREPACK_HOME="${COREPACK_HOME:-${TMPDIR:-/tmp}/corepack-sib-swiss-federated-query-extractor}"
  mkdir -p "$COREPACK_HOME"
  YARN_CMD=(corepack yarn)
else
  YARN_CMD=(yarn)
fi

echo "Installing JS dependencies..."
"${YARN_CMD[@]}" install

echo "Extracting federated queries..."
"${YARN_CMD[@]}" run extract "$@"

echo "Done. Output written to sib-swiss-federated-queries.json"
