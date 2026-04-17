# SlateDB Zig Binding

This directory contains the official Zig binding for SlateDB.

This binding is still early. It is a handwritten Zig wrapper over the existing
UniFFI C ABI and shared library. It supports both blocking helpers and
future-based async calls built on Zig `std.Io`.

## What Works Today

Core:
- links against the existing `slatedb-uniffi` shared library
- uses the checked-in UniFFI C header
- validates the UniFFI contract version and API checksums
- includes Linux CI coverage for the Zig binding

Builders and object store:
- supports `ObjectStore.resolve`
- supports `DbBuilder.init`
- supports `DbBuilder.build`
- supports `DbBuilder.buildBlocking`
- supports `DbBuilder.withWalObjectStore`
- supports `DbReaderBuilder.init`
- supports `DbReaderBuilder.build`
- supports `DbReaderBuilder.buildBlocking`
- supports `DbReaderBuilder.withOptions`
- supports `DbReaderBuilder.withWalObjectStore`

Database:
- supports `Db.status`
- supports `Db.put`
- supports `Db.putBlocking`
- supports `Db.putWithOptions`
- supports `Db.putWithOptionsBlocking`
- supports `Db.get`
- supports `Db.getBlocking`
- supports `Db.getWithOptions`
- supports `Db.getWithOptionsBlocking`
- supports `Db.getKeyValue`
- supports `Db.getKeyValueBlocking`
- supports `Db.getKeyValueWithOptions`
- supports `Db.getKeyValueWithOptionsBlocking`
- supports `Db.scan`
- supports `Db.scanBlocking`
- supports `Db.scanPrefix`
- supports `Db.scanPrefixBlocking`
- supports `Db.scanWithOptions`
- supports `Db.scanWithOptionsBlocking`
- supports `Db.scanPrefixWithOptions`
- supports `Db.scanPrefixWithOptionsBlocking`
- supports `Db.delete`
- supports `Db.deleteBlocking`
- supports `Db.deleteWithOptions`
- supports `Db.deleteWithOptionsBlocking`
- supports `Db.snapshot`
- supports `Db.snapshotBlocking`
- supports `Db.write`
- supports `Db.writeBlocking`
- supports `Db.writeWithOptions`
- supports `Db.writeWithOptionsBlocking`
- supports `Db.flush`
- supports `Db.flushBlocking`
- supports `Db.flushWithOptions`
- supports `Db.flushWithOptionsBlocking`
- supports `Db.shutdown`
- supports `Db.shutdownBlocking`
- supports `Db.begin`
- supports `Db.beginBlocking`

Reader:
- supports `DbReader.get`
- supports `DbReader.getBlocking`
- supports `DbReader.getWithOptions`
- supports `DbReader.getWithOptionsBlocking`
- supports `DbReader.scan`
- supports `DbReader.scanBlocking`
- supports `DbReader.scanPrefix`
- supports `DbReader.scanPrefixBlocking`
- supports `DbReader.scanWithOptions`
- supports `DbReader.scanWithOptionsBlocking`
- supports `DbReader.scanPrefixWithOptions`
- supports `DbReader.scanPrefixWithOptionsBlocking`
- supports `DbReader.shutdown`
- supports `DbReader.shutdownBlocking`

Snapshots and transactions:
- supports `DbSnapshot.get`
- supports `DbSnapshot.getBlocking`
- supports `DbSnapshot.getWithOptions`
- supports `DbSnapshot.getWithOptionsBlocking`
- supports `DbSnapshot.getKeyValue`
- supports `DbSnapshot.getKeyValueBlocking`
- supports `DbSnapshot.getKeyValueWithOptions`
- supports `DbSnapshot.getKeyValueWithOptionsBlocking`
- supports `DbSnapshot.scan`
- supports `DbSnapshot.scanBlocking`
- supports `DbSnapshot.scanPrefix`
- supports `DbSnapshot.scanPrefixBlocking`
- supports `DbSnapshot.scanWithOptions`
- supports `DbSnapshot.scanWithOptionsBlocking`
- supports `DbSnapshot.scanPrefixWithOptions`
- supports `DbSnapshot.scanPrefixWithOptionsBlocking`
- supports `DbTransaction.id`
- supports `DbTransaction.seqnum`
- supports `DbTransaction.put`
- supports `DbTransaction.putBlocking`
- supports `DbTransaction.putWithOptions`
- supports `DbTransaction.putWithOptionsBlocking`
- supports `DbTransaction.get`
- supports `DbTransaction.getBlocking`
- supports `DbTransaction.getWithOptions`
- supports `DbTransaction.getWithOptionsBlocking`
- supports `DbTransaction.getKeyValue`
- supports `DbTransaction.getKeyValueBlocking`
- supports `DbTransaction.getKeyValueWithOptions`
- supports `DbTransaction.getKeyValueWithOptionsBlocking`
- supports `DbTransaction.scan`
- supports `DbTransaction.scanBlocking`
- supports `DbTransaction.scanPrefix`
- supports `DbTransaction.scanPrefixBlocking`
- supports `DbTransaction.scanWithOptions`
- supports `DbTransaction.scanWithOptionsBlocking`
- supports `DbTransaction.scanPrefixWithOptions`
- supports `DbTransaction.scanPrefixWithOptionsBlocking`
- supports `DbTransaction.commit`
- supports `DbTransaction.commitBlocking`
- supports `DbTransaction.commitWithOptions`
- supports `DbTransaction.commitWithOptionsBlocking`
- supports `DbTransaction.rollback`
- supports `DbTransaction.rollbackBlocking`

Iterators, batches, and exported types:
- supports `DbIterator.next`
- supports `DbIterator.nextBlocking`
- supports `DbIterator.seek`
- supports `DbIterator.seekBlocking`
- supports `WalReader.init`
- supports `WalReader.get`
- supports `WalReader.list`
- supports `WalReader.listBlocking`
- supports `WalFile.id`
- supports `WalFile.nextId`
- supports `WalFile.nextFile`
- supports `WalFile.metadata`
- supports `WalFile.metadataBlocking`
- supports `WalFile.iterator`
- supports `WalFile.iteratorBlocking`
- supports `WalFileIterator.next`
- supports `WalFileIterator.nextBlocking`
- exports `CallErrorDetail`
- supports `takeLastCallErrorDetail`
- supports `clearLastCallErrorDetail`
- exports `KeyRange`
- exports `KeyValue`
- exports `RowEntry`
- exports `RowEntryKind`
- exports `DurabilityLevel`
- exports `FlushOptions`
- exports `FlushType`
- exports `MergeOptions`
- exports `PutOptions`
- exports `ReadOptions`
- exports `ReaderOptions`
- exports `ScanOptions`
- exports `Ttl`
- exports `WriteHandle`
- exports `WriteOptions`
- exports `WalFileMetadata`
- supports `WriteBatch.init`
- supports `WriteBatch.put`
- supports `WriteBatch.putWithOptions`
- supports `WriteBatch.delete`

## What Is Next

- metrics support
- logging and merge-operator callbacks

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

The build script adds an rpath for the default shared library directory. If the
library lives somewhere else, pass:

```bash
zig build test -Dslatedb-lib-dir=/absolute/path/to/target/debug
```

If your runtime loader still cannot find `libslatedb_uniffi`, set
`LD_LIBRARY_PATH` on Linux or `DYLD_LIBRARY_PATH` on macOS before running
`zig build test`.

## Error Details

Calls still return normal Zig error sets like `error.Invalid` or `error.Closed`.
If you need the typed payload from the last SlateDB call, take it right after
the failing call.

Example:

```zig
var put_future = db.put(io, "", "value");
try std.testing.expectError(error.Invalid, put_future.await(io));

var detail = (try slatedb.takeLastCallErrorDetail(std.testing.allocator)).?;
defer detail.deinit(std.testing.allocator);

switch (detail) {
    .invalid => |message| std.debug.print("invalid: {s}\n", .{message}),
    else => unreachable,
}
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

The Zig binding now covers the main async and blocking database path, option
structs and option-based methods, typed call error details, reader reads and
scans, write batches, snapshots, transactions, iterators, WAL inspection, and
Linux CI. It is still behind the Go binding for metrics and callbacks.
