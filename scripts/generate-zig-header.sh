#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
UNIFFI_DIR="${ROOT_DIR}/bindings/uniffi"
ZIG_INCLUDE_DIR="${ROOT_DIR}/bindings/zig/include"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/slatedb-zig-uniffi.XXXXXX")"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

if ! command -v uniffi-bindgen-go >/dev/null 2>&1; then
  echo "uniffi-bindgen-go is required on PATH" >&2
  echo "Install it with:" >&2
  echo "  cargo install uniffi-bindgen-go --git https://github.com/NordSecurity/uniffi-bindgen-go --tag v0.7.0+v0.31.0" >&2
  exit 1
fi

cargo build --manifest-path "${ROOT_DIR}/Cargo.toml" -p slatedb-uniffi

LIB_FILE=""
for candidate in \
  "${ROOT_DIR}/target/debug/libslatedb_uniffi.so" \
  "${ROOT_DIR}/target/debug/libslatedb_uniffi.dylib" \
  "${ROOT_DIR}/target/debug/slatedb_uniffi.dll"; do
  if [[ -f "${candidate}" ]]; then
    LIB_FILE="${candidate}"
    break
  fi
done

if [[ -z "${LIB_FILE}" ]]; then
  echo "failed to locate built slatedb-uniffi library under target/debug" >&2
  exit 1
fi

mkdir -p "${ZIG_INCLUDE_DIR}"

uniffi-bindgen-go "${LIB_FILE}" \
  --library \
  --config "${UNIFFI_DIR}/uniffi.toml" \
  --out-dir "${TMP_DIR}/out"

GENERATED_DIR="${TMP_DIR}/out/slatedb"
GENERATED_H_FILE="$(find "${GENERATED_DIR}" -maxdepth 1 -type f -name '*.h' | head -n 1)"

if [[ -z "${GENERATED_H_FILE}" ]]; then
  echo "unexpected generator output in ${GENERATED_DIR}" >&2
  exit 1
fi

cp "${GENERATED_H_FILE}" "${ZIG_INCLUDE_DIR}/slatedb.h"
