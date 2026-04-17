const std = @import("std");
const codec = @import("codec.zig");
const ffi = @import("ffi.zig");
const object_handle = @import("object_handle.zig");
const rust_buffer = @import("rust_buffer.zig");
const rust_call = @import("rust_call.zig");
const rust_future = @import("rust_future.zig");

pub const WriteHandle = codec.WriteHandle;

pub const DbTransaction = struct {
    handle: object_handle.ObjectHandle,

    pub fn fromRaw(raw: ?*anyopaque) DbTransaction {
        return .{
            .handle = object_handle.ObjectHandle.init(
                raw,
                ffi.c.uniffi_slatedb_uniffi_fn_clone_dbtransaction,
                ffi.c.uniffi_slatedb_uniffi_fn_free_dbtransaction,
            ),
        };
    }

    pub fn id(
        self: *DbTransaction,
        allocator: std.mem.Allocator,
    ) (std.mem.Allocator.Error || rust_call.CallError)![]u8 {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        var status = std.mem.zeroes(ffi.c.RustCallStatus);
        const raw = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_id(tx_handle, &status);
        try rust_call.checkStatus(status);

        var result_buffer = rust_buffer.RustBuffer{ .raw = raw };
        defer result_buffer.deinit();

        return allocator.dupe(u8, result_buffer.bytes());
    }

    pub fn seqnum(self: *DbTransaction) rust_call.CallError!u64 {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        var status = std.mem.zeroes(ffi.c.RustCallStatus);
        const value = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_seqnum(tx_handle, &status);
        try rust_call.checkStatus(status);
        return value;
    }

    pub fn put(
        self: *DbTransaction,
        io: std.Io,
        key: []const u8,
        value: []const u8,
    ) std.Io.Future((std.mem.Allocator.Error || rust_call.CallError)!void) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!void,
                call_err,
            );
        };

        const tx_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!void,
                call_err,
            );
        };

        const key_buffer = rust_buffer.RustBuffer.fromSerializedBytes(key) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!void,
                call_err,
            );
        };
        const value_buffer = rust_buffer.RustBuffer.fromSerializedBytes(value) catch |call_err| {
            self.handle.finishRustCall();
            return rust_future.ready(
                (std.mem.Allocator.Error || rust_call.CallError)!void,
                call_err,
            );
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_put(
            tx_handle,
            key_buffer.raw,
            value_buffer.raw,
        );

        return io.async(waitPutTask, .{ &self.handle, future });
    }

    pub fn putBlocking(
        self: *DbTransaction,
        key: []const u8,
        value: []const u8,
    ) (std.mem.Allocator.Error || rust_call.CallError)!void {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const key_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(key);
        const value_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(value);
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_put(
            tx_handle,
            key_buffer.raw,
            value_buffer.raw,
        );

        try rust_future.waitVoid(future);
    }

    pub fn get(
        self: *DbTransaction,
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

        const tx_handle = self.handle.beginRustCall() catch |call_err| {
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

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_get(
            tx_handle,
            key_buffer.raw,
        );

        return io.async(waitGetTask, .{ &self.handle, allocator, future });
    }

    pub fn getBlocking(
        self: *DbTransaction,
        allocator: std.mem.Allocator,
        key: []const u8,
    ) (std.mem.Allocator.Error || rust_call.CallError)!?[]u8 {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const key_buffer = try rust_buffer.RustBuffer.fromSerializedBytes(key);
        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_get(
            tx_handle,
            key_buffer.raw,
        );

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const value = try codec.decodeOptionalBytes(allocator, &reader);
        try reader.finish();
        return value;
    }

    pub fn commit(self: *DbTransaction, io: std.Io) std.Io.Future(rust_call.CallError!?WriteHandle) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(rust_call.CallError!?WriteHandle, call_err);
        };

        const tx_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(rust_call.CallError!?WriteHandle, call_err);
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_commit(tx_handle);
        return io.async(waitCommitTask, .{ &self.handle, future });
    }

    pub fn commitBlocking(self: *DbTransaction) rust_call.CallError!?WriteHandle {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_commit(tx_handle);

        var result_buffer = try rust_future.waitRustBuffer(future);
        defer result_buffer.deinit();

        var reader = codec.BufferReader.init(result_buffer.bytes());
        const handle = try codec.decodeOptionalWriteHandle(&reader);
        try reader.finish();
        return handle;
    }

    pub fn rollback(self: *DbTransaction, io: std.Io) std.Io.Future(rust_call.CallError!void) {
        ffi.ensureCompatible() catch |call_err| {
            return rust_future.ready(rust_call.CallError!void, call_err);
        };

        const tx_handle = self.handle.beginRustCall() catch |call_err| {
            return rust_future.ready(rust_call.CallError!void, call_err);
        };

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_rollback(tx_handle);
        return rust_future.asyncVoid(io, &self.handle, future);
    }

    pub fn rollbackBlocking(self: *DbTransaction) rust_call.CallError!void {
        try ffi.ensureCompatible();

        const tx_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbtransaction_rollback(tx_handle);
        try rust_future.waitVoid(future);
    }

    pub fn deinit(self: *DbTransaction) void {
        self.handle.deinit();
    }
};

fn waitPutTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) (std.mem.Allocator.Error || rust_call.CallError)!void {
    defer owner.finishRustCall();
    try rust_future.waitVoid(handle);
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

fn waitCommitTask(
    owner: *object_handle.ObjectHandle,
    handle: u64,
) rust_call.CallError!?WriteHandle {
    defer owner.finishRustCall();

    var result_buffer = try rust_future.waitRustBuffer(handle);
    defer result_buffer.deinit();

    var reader = codec.BufferReader.init(result_buffer.bytes());
    const write_handle = try codec.decodeOptionalWriteHandle(&reader);
    try reader.finish();
    return write_handle;
}
