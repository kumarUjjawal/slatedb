const std = @import("std");

pub const CallError = error{
    ApiChecksumMismatch,
    BufferTooLarge,
    Closed,
    ContractVersionMismatch,
    Data,
    Internal,
    Invalid,
    ObjectDestroyed,
    RustPanic,
    RustPanicWhileHandlingPanic,
    Transaction,
    UnexpectedEnumTag,
    UnexpectedRustBufferData,
    Unavailable,
    UnexpectedEndOfBuffer,
};

pub const CloseReason = enum(i32) {
    clean = 1,
    fenced = 2,
    background_panic = 3,
    unknown = 4,
};

pub const ApiErrorPayload = union(enum) {
    transaction: []const u8,
    closed: struct {
        reason: CloseReason,
        message: []const u8,
    },
    unavailable: []const u8,
    invalid: []const u8,
    data: []const u8,
    internal: []const u8,
};

pub fn toCallError(payload: ApiErrorPayload) CallError {
    return switch (payload) {
        .transaction => error.Transaction,
        .closed => error.Closed,
        .unavailable => error.Unavailable,
        .invalid => error.Invalid,
        .data => error.Data,
        .internal => error.Internal,
    };
}

pub fn logApiError(payload: ApiErrorPayload) void {
    switch (payload) {
        .transaction => |message| std.log.err("SlateDB transaction error: {s}", .{message}),
        .closed => |closed| std.log.err(
            "SlateDB closed error ({s}): {s}",
            .{ @tagName(closed.reason), closed.message },
        ),
        .unavailable => |message| std.log.err("SlateDB unavailable error: {s}", .{message}),
        .invalid => |message| std.log.err("SlateDB invalid error: {s}", .{message}),
        .data => |message| std.log.err("SlateDB data error: {s}", .{message}),
        .internal => |message| std.log.err("SlateDB internal error: {s}", .{message}),
    }
}
