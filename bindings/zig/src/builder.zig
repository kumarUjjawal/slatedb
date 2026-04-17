const std = @import("std");
const db = @import("db.zig");
const ffi = @import("ffi.zig");
const object_handle = @import("object_handle.zig");
const object_store = @import("object_store.zig");
const rust_buffer = @import("rust_buffer.zig");
const rust_call = @import("rust_call.zig");
const rust_future = @import("rust_future.zig");

pub const DbBuilder = struct {
    handle: object_handle.ObjectHandle,

    pub fn init(path: []const u8, store: *const object_store.ObjectStore) rust_call.CallError!DbBuilder {
        try ffi.ensureCompatible();

        const path_buffer = try rust_buffer.RustBuffer.fromBytes(path);
        const store_handle = try @constCast(&store.handle).beginRustCall();
        defer @constCast(&store.handle).finishRustCall();

        var status = std.mem.zeroes(ffi.c.RustCallStatus);
        const raw = ffi.c.uniffi_slatedb_uniffi_fn_constructor_dbbuilder_new(
            path_buffer.raw,
            store_handle,
            &status,
        );
        try rust_call.checkStatus(status);

        return .{
            .handle = object_handle.ObjectHandle.init(
                raw,
                ffi.c.uniffi_slatedb_uniffi_fn_clone_dbbuilder,
                ffi.c.uniffi_slatedb_uniffi_fn_free_dbbuilder,
            ),
        };
    }

    pub fn buildBlocking(self: *DbBuilder) rust_call.CallError!db.Db {
        try ffi.ensureCompatible();

        const builder_handle = try self.handle.beginRustCall();
        defer self.handle.finishRustCall();

        const future = ffi.c.uniffi_slatedb_uniffi_fn_method_dbbuilder_build(builder_handle);
        const raw_db = try rust_future.waitPointer(future);
        return db.Db.fromRaw(raw_db);
    }

    pub fn deinit(self: *DbBuilder) void {
        self.handle.deinit();
    }
};
