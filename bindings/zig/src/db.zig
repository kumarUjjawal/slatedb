const std = @import("std");
const codec = @import("codec.zig");
const ffi = @import("ffi.zig");
const object_handle = @import("object_handle.zig");
const rust_buffer = @import("rust_buffer.zig");
const rust_call = @import("rust_call.zig");
const rust_future = @import("rust_future.zig");

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

    pub fn shutdownBlocking(self: *Db) rust_call.CallError!void {
        try ffi.ensureCompatible();

        const db_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_db_shutdown(db_handle);
        try rust_future.waitVoid(future);
    }

    pub fn deinit(self: *Db) void {
        self.handle.deinit();
    }
};
