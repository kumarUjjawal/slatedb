const std = @import("std");
const codec = @import("codec.zig");
const config = @import("config.zig");
const db_snapshot = @import("db_snapshot.zig");
const db_transaction = @import("db_transaction.zig");
const ffi = @import("ffi.zig");
const object_handle = @import("object_handle.zig");
const rust_buffer = @import("rust_buffer.zig");
const rust_call = @import("rust_call.zig");
const rust_future = @import("rust_future.zig");
const write_batch = @import("write_batch.zig");

pub const WriteHandle = codec.WriteHandle;

pub const Db = struct {
    handle: object_handle.ObjectHandle,

    pub fn fromRaw(raw: ?*anyopaque) Db {
        return .{
            .handle = object_handle.ObjectHandle.init(
                raw,
                ffi.c.uniffi_slatedb_uniffi_fn_clone_db,
                ffi.c.uniffi_slatedb_uniffi_fn_free_db,
            ),
        };
    }

    pub fn status(self: *Db) rust_call.CallError!void {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        var status_info = std.mem.zeroes(ffi.c.RustCallStatus);
        ffi.c.uniffi_slatedb_uniffi_fn_method_db_status(db_handle, &status_info);
        try rust_call.checkStatus(status_info);
    }

    pub fn begin(
        self: *Db,
        io: std.Io,
        isolation_level: config.IsolationLevel,
    ) std.Io.Future(rust_call.CallError!db_transaction.DbTransaction) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(
                rust_call.CallError!db_transaction.DbTransaction,
                call_err,
            );
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(
                rust_call.CallError!db_transaction.DbTransaction,
                call_err,
            );
        };

        const isolation_level_buffer = rust_buffer.RustBuffer.fromI32(
            @intFromEnum(isolation_level),
        ) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                rust_call.CallError!db_transaction.DbTransaction,
                call_err,
            );
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_begin(
            db_handle,
            isolation_level_buffer.raw,
        );
        return io.async(waitBeginTask, .{ &self.handle, future });
    }

    pub fn beginBlocking(
        self: *Db,
        isolation_level: config.IsolationLevel,
    ) rust_call.CallError!db_transaction.DbTransaction {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const isolation_level_buffer = try rust_buffer.RustBuffer.fromI32(
            @intFromEnum(isolation_level),
        );
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_begin(
            db_handle,
            isolation_level_buffer.raw,
        );
        const raw_tx = try rust_future.waitPointer(future);
        return db_transaction.DbTransaction.fromRaw(raw_tx);
    }

    pub fn put(
        self: *Db,
        io: std.Io,
        key: []const u8,
        value: []const u8,
    ) std.Io.Future((std.mem.Allocator.Error || rust_call.CallError)!WriteHandle) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const key_buffer = rust_buffer.RustBuffer.fromSerializedBytes(key) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };
        const value_buffer = rust_buffer.RustBuffer.fromSerializedBytes(value) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_put(
            db_handle,
            key_buffer.raw,
            value_buffer.raw,
        );

        return io.async(waitPutTask, .{ &self.handle, future });
    }

    pub fn putBlocking(
        self: *Db,
        key: []const u8,
        value: []const u8,
    ) (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const key_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(key);
        const value_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(value);
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_put(
            db_handle,
            key_buffer.raw,
            value_buffer.raw,
        );

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const handle = try codec.decodeWriteHandle(&reader);
        try reader.finish();
        return handle;
    }

    pub fn get(
        self: *Db,
        io: std.Io,
        allocator: std.mem.Allocator,
        key: []const u8,
    ) std.Io.Future((std.mem.Allocator.Error || rust_call.CallError)!?[]u8) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!?[]u8,
                call_err,
            );
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!?[]u8,
                call_err,
            );
        };

        const key_buffer = rust_buffer.RustBuffer.fromSerializedBytes(key) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!?[]u8,
                call_err,
            );
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_get(
            db_handle,
            key_buffer.raw,
        );

        return io.async(waitGetTask, .{ &self.handle, allocator, future });
    }

    pub fn getBlocking(
        self: *Db,
        allocator: std.mem.Allocator,
        key: []const u8,
    ) (std.mem.Allocator.Error || rust_call.CallError)!?[]u8 {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const key_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(key);
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_get(
            db_handle,
            key_buffer.raw,
        );

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const value = try codec.decodeOptionalBytes(allocator, &reader);
        try reader.finish();
        return value;
    }

    pub fn delete(
        self: *Db,
        io: std.Io,
        key: []const u8,
    ) std.Io.Future((std.mem.Allocator.Error || rust_call.CallError)!WriteHandle) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const key_buffer = rust_buffer.RustBuffer.fromSerializedBytes(key) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle,
                call_err,
            );
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_delete(
            db_handle,
            key_buffer.raw,
        );

        return io.async(waitDeleteTask, .{ &self.handle, future });
    }

    pub fn deleteBlocking(
        self: *Db,
        key: []const u8,
    ) (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const key_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(key);
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_delete(
            db_handle,
            key_buffer.raw,
        );

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const handle = try codec.decodeWriteHandle(&reader);
        try reader.finish();
        return handle;
    }

    pub fn shutdown(self: *Db, io: std.Io) std.Io.Future(rust_call.CallError!void) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(rust_call.CallError!void, call_err);
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(rust_call.CallError!void, call_err);
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_shutdown(db_handle);
        return rust_future.asyncVoid(io, &self.handle, future);
    }

    pub fn snapshot(self: *Db, io: std.Io) std.Io.Future(rust_call.CallError!db_snapshot.DbSnapshot) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(rust_call.CallError!db_snapshot.DbSnapshot, call_err);
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(rust_call.CallError!db_snapshot.DbSnapshot, call_err);
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_snapshot(db_handle);
        return io.async(waitSnapshotTask, .{ &self.handle, future });
    }

    pub fn write(
        self: *Db,
        io: std.Io,
        batch: *write_batch.WriteBatch,
    ) std.Io.Future(rust_call.CallError!WriteHandle) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(rust_call.CallError!WriteHandle, call_err);
        };

        const db_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(rust_call.CallError!WriteHandle, call_err);
        };

        const batch_handle = batch.handle.beginRustCall() catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(rust_call.CallError!WriteHandle, call_err);
        };
        defer batch.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_write(
            db_handle,
            batch_handle,
        );
        return io.async(waitWriteTask, .{ &self.handle, future });
    }

    pub fn shutdownBlocking(self: *Db) rust_call.CallError!void {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_shutdown(db_handle);
        try rust_future.waitVoid(future);
    }

    pub fn snapshotBlocking(self: *Db) rust_call.CallError!db_snapshot.DbSnapshot {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_snapshot(db_handle);
        const raw_snapshot = try rust_future.waitPointer(future);
        return db_snapshot.DbSnapshot.fromRaw(raw_snapshot);
    }

    pub fn writeBlocking(
        self: *Db,
        batch: *write_batch.WriteBatch,
    ) rust_call.CallError!WriteHandle {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const batch_handle = try batch.handle.beginRustCall();
        defer batch.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_write(
            db_handle,
            batch_handle,
        );

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const handle = try codec.decodeWriteHandle(&reader);
        try reader.finish();
        return handle;
    }

    pub fn deinit(self: *Db) void {
        self.handle.deinit();
    }
};

fn waitPutTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle {
    defer owner.finishRustCall();

    var result_buffer = try rust_future.waitRustBuffer(handle);
    defer result_buffer.deinit();

    var reader = codec.BufferReader.init(result_buffer.bytes());
    const write_handle = try codec.decodeWriteHandle(&reader);
    try reader.finish();
    return write_handle;
}

fn waitBeginTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) rust_call.CallError!db_transaction.DbTransaction {
    defer owner.finishRustCall();

    const raw_tx = try rust_future.waitPointer(handle);
    return db_transaction.DbTransaction.fromRaw(raw_tx);
}

fn waitGetTask(
    owner: *object_handle.ObjectHandle,
    allocator: std.mem.Allocator,
    handle: u64,
) (std.mem.Allocator.Error || rust_call.CallError)!?[]u8 {
    defer owner.finishRustCall();

    var result_buffer = try rust_future.waitRustBuffer(handle);
    defer result_buffer.deinit();

    var reader = codec.BufferReader.init(result_buffer.bytes());
    const value = try codec.decodeOptionalBytes(allocator, &reader);
    try reader.finish();
    return value;
}

fn waitDeleteTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) (std.mem.Allocator.Error || rust_call.CallError)!WriteHandle {
    defer owner.finishRustCall();

    var result_buffer = try rust_future.waitRustBuffer(handle);
    defer result_buffer.deinit();

    var reader = codec.BufferReader.init(result_buffer.bytes());
    const write_handle = try codec.decodeWriteHandle(&reader);
    try reader.finish();
    return write_handle;
}

fn waitWriteTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) rust_call.CallError!WriteHandle {
    defer owner.finishRustCall();

    var result_buffer = try rust_future.waitRustBuffer(handle);
    defer result_buffer.deinit();

    var reader = codec.BufferReader.init(result_buffer.bytes());
    const write_handle = try codec.decodeWriteHandle(&reader);
    try reader.finish();
    return write_handle;
}

fn waitSnapshotTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) rust_call.CallError!db_snapshot.DbSnapshot {
    defer owner.finishRustCall();

    const raw_snapshot = try rust_future.waitPointer(handle);
    return db_snapshot.DbSnapshot.fromRaw(raw_snapshot);
}
