# SlateDB Zig Binding

This directory contains the Zig binding for SlateDB.

Current scope:

- links against the existing `slatedb-uniffi` shared library
- uses the checked-in UniFFI C header
- validates the UniFFI contract version and the first API checksums
- includes a small Zig test that proves the binding links and can call the ABI

## Zig Version

This package is pinned to Zig `0.16.0`.

## Prerequisites

- Rust toolchain from this repository
- Zig `0.16.0`
- a working C toolchain
- `uniffi-bindgen-go` `0.7.0+v0.31.0` if you want to regenerate the header

## Regenerate The Header

From the repository root:

```bash
./scripts/generate-zig-header.sh
```

The generated header is checked in. Zig build output stays in `.zig-cache/` or
`zig-out/` and should not be committed.

## Build And Test

From the repository root:

```bash
cargo build -p slatedb-uniffi
./scripts/generate-zig-header.sh
cd bindings/zig
zig build test
```

If the shared library lives somewhere else, pass:

```bash
zig build test -Dslatedb-lib-dir=/absolute/path/to/target/debug
```

## Current Status

This is an early handwritten binding over the UniFFI C ABI.

- the scaffold, header import, and ABI checks are in place
- native Zig `async/await` wrappers are still planned
- wider API parity with the Go binding is still in progress
