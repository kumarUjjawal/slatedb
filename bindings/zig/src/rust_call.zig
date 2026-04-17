const std = @import("std");
const codec = @import("codec.zig");
const err = @import("error.zig");
const ffi = @import("ffi.zig");
const rust_buffer = @import("rust_buffer.zig");

pub const CallError = err.CallError;

pub fn checkStatus(status: ffi.c.RustCallStatus) CallError!void {
    return switch (status.code) {
        0 => {},
        1 => handleApiError(status.errorBuf),
        2 => handleRustPanic(status.errorBuf),
        else => {
            std.log.err("unexpected RustCallStatus code: {d}", .{status.code});
            return error.Internal;
        },
    };
}

fn handleApiError(raw: ffi.c.RustBuffer) CallError {
    var error_buffer = rust_buffer.RustBuffer{ .raw = raw };
    defer error_buffer.deinit();

    var reader = codec.BufferReader.init(error_buffer.bytes());
    const payload = codec.decodeApiError(&reader) catch |decode_err| {
        std.log.err("failed to decode SlateDB API error: {s}", .{@errorName(decode_err)});
        return error.Internal;
    };

    reader.finish() catch |decode_err| {
        std.log.err("SlateDB API error buffer had trailing data: {s}", .{@errorName(decode_err)});
        return error.Internal;
    };

    return err.toCallError(payload);
}

fn handleRustPanic(raw: ffi.c.RustBuffer) CallError {
    var panic_buffer = rust_buffer.RustBuffer{ .raw = raw };
    defer panic_buffer.deinit();

    if (panic_buffer.raw.len == 0) {
        std.log.err("Rust panicked while handling a Rust panic", .{});
        return error.RustPanicWhileHandlingPanic;
    }

    const message = panic_buffer.bytes();
    std.log.err("Rust panic: {s}", .{message});
    return error.RustPanic;
}
