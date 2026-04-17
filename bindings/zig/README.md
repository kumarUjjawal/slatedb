# SlateDB Zig Binding

This directory contains the official Zig binding for SlateDB.

This binding is still early. It is a handwritten Zig wrapper over the existing
UniFFI C ABI and shared library. It supports both blocking helpers and
future-based async calls built on Zig `std.Io`.

## What Works Today

- links against the existing `slatedb-uniffi` shared library
- uses the checked-in UniFFI C header
- validates the UniFFI contract version and the first API checksums
- includes a first blocking database path
- supports `ObjectStore.resolve`
- supports `DbBuilder.init`
- supports `DbBuilder.build`
- supports `DbBuilder.buildBlocking`
- supports `Db.status`
- supports `Db.put`
- supports `Db.putBlocking`
- supports `Db.get`
- supports `Db.getBlocking`
- supports `Db.delete`
- supports `Db.deleteBlocking`
- supports `Db.snapshot`
- supports `Db.snapshotBlocking`
- supports `Db.write`
- supports `Db.writeBlocking`
- supports `Db.shutdown`
- supports `Db.shutdownBlocking`
- supports `Db.begin`
- supports `Db.beginBlocking`
- supports `DbSnapshot.get`
- supports `DbSnapshot.getBlocking`
- supports `DbTransaction.id`
- supports `DbTransaction.seqnum`
- supports `DbTransaction.put`
- supports `DbTransaction.putBlocking`
- supports `DbTransaction.get`
- supports `DbTransaction.getBlocking`
- supports `DbTransaction.commit`
- supports `DbTransaction.commitBlocking`
- supports `DbTransaction.rollback`
- supports `DbTransaction.rollbackBlocking`
- supports `WriteBatch.init`
- supports `WriteBatch.put`
- supports `WriteBatch.delete`

## What Is Next

- scan and iterator support
- reader support
- richer typed error details
- metrics support
- logging and merge-operator callbacks
- WAL reader support
- CI coverage for the Zig binding

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

## Async Style

With Zig `0.16.0`, the async path uses `std.Io.Future` and `future.await(io)`.

Example:

```zig
var threaded = std.Io.Threaded.init(std.heap.smp_allocator, .{});
defer threaded.deinit();
const io = threaded.io();

var store = try slatedb.ObjectStore.resolve("memory:///");
defer store.deinit();

var builder = try slatedb.DbBuilder.init("zig-demo", &store);
defer builder.deinit();

var build_future = builder.build(io);
var db = try build_future.await(io);
defer db.deinit();

var put_future = db.put(io, "hello", "world");
_ = try put_future.await(io);

var get_future = db.get(io, std.heap.smp_allocator, "hello");
const value = try get_future.await(io);
defer if (value) |bytes| std.heap.smp_allocator.free(bytes);
```

## Current Status

The Zig binding now covers the core async and blocking database path, write
batches, snapshots, and basic transactions. It is still behind the Go binding
for scans, reader APIs, callbacks, metrics, WAL access, and CI coverage.
