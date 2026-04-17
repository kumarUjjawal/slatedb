# SlateDB Zig Binding

This directory contains the official Zig binding for SlateDB.

This binding is still early. It is a handwritten Zig wrapper over the existing
UniFFI C ABI and shared library.

## What Works Today

- links against the existing `slatedb-uniffi` shared library
- uses the checked-in UniFFI C header
- validates the UniFFI contract version and the first API checksums
- includes a first blocking database path
- supports `ObjectStore.resolve`
- supports `DbBuilder.init`
- supports `DbBuilder.buildBlocking`
- supports `Db.status`
- supports `Db.putBlocking`
- supports `Db.getBlocking`
- supports `Db.deleteBlocking`
- supports `Db.shutdownBlocking`

## What Is Next

- native Zig `async/await` wrappers
- wider API coverage to match the Go binding
- more tests ported from the other bindings

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

The first blocking database path is implemented and covered by Zig smoke tests.
The binding is not feature-complete yet.
