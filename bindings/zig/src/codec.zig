const std = @import("std");
const err = @import("error.zig");

pub const WriteHandle = struct {
    seqnum: u64,
    create_ts: i64,
};

pub const BufferReader = struct {
    bytes: []const u8,
    pos: usize = 0,

    pub fn init(bytes: []const u8) BufferReader {
        return .{ .bytes = bytes };
    }

    pub fn finish(self: *BufferReader) err.CallError!void {
        if (self.pos != self.bytes.len) {
            return error.UnexpectedRustBufferData;
        }
    }

    pub fn readInt8(self: *BufferReader) err.CallError!i8 {
        const value = try self.readByte();
        return @bitCast(value);
    }

    pub fn readI32(self: *BufferReader) err.CallError!i32 {
        return @bitCast(try self.readU32());
    }

    pub fn readU32(self: *BufferReader) err.CallError!u32 {
        const bytes = try self.readSlice(4);
        return std.mem.readInt(u32, bytes[0..4], .big);
    }

    pub fn readU64(self: *BufferReader) err.CallError!u64 {
        const bytes = try self.readSlice(8);
        return std.mem.readInt(u64, bytes[0..8], .big);
    }

    pub fn readI64(self: *BufferReader) err.CallError!i64 {
        return @bitCast(try self.readU64());
    }

    pub fn readSlice(self: *BufferReader, len: usize) err.CallError![]const u8 {
        if (self.pos + len > self.bytes.len) {
            return error.UnexpectedEndOfBuffer;
        }
        const out = self.bytes[self.pos .. self.pos + len];
        self.pos += len;
        return out;
    }

    fn readByte(self: *BufferReader) err.CallError!u8 {
        if (self.pos >= self.bytes.len) {
            return error.UnexpectedEndOfBuffer;
        }
        const value = self.bytes[self.pos];
        self.pos += 1;
        return value;
    }
};

pub fn decodeLiftedString(bytes: []const u8) err.CallError![]const u8 {
    var reader = BufferReader.init(bytes);
    const value = try decodeString(&reader);
    try reader.finish();
    return value;
}

pub fn decodeString(reader: *BufferReader) err.CallError![]const u8 {
    const len = try reader.readI32();
    if (len < 0) {
        return error.UnexpectedRustBufferData;
    }
    return reader.readSlice(@intCast(len));
}

pub fn decodeOptionalBytes(
    allocator: std.mem.Allocator,
    reader: *BufferReader,
) (std.mem.Allocator.Error || err.CallError)!?[]u8 {
    return switch (try reader.readInt8()) {
        0 => null,
        1 => {
            const bytes = try decodeBytes(reader);
            const owned = try allocator.dupe(u8, bytes);
            return @as(?[]u8, owned);
        },
        else => error.UnexpectedEnumTag,
    };
}

pub fn decodeWriteHandle(reader: *BufferReader) err.CallError!WriteHandle {
    return .{
        .seqnum = try reader.readU64(),
        .create_ts = try reader.readI64(),
    };
}

pub fn decodeApiError(reader: *BufferReader) err.CallError!err.ApiErrorPayload {
    return switch (try reader.readU32()) {
        1 => .{ .transaction = try decodeString(reader) },
        2 => .{
            .closed = .{
                .reason = try decodeCloseReason(reader),
                .message = try decodeString(reader),
            },
        },
        3 => .{ .unavailable = try decodeString(reader) },
        4 => .{ .invalid = try decodeString(reader) },
        5 => .{ .data = try decodeString(reader) },
        6 => .{ .internal = try decodeString(reader) },
        else => error.UnexpectedEnumTag,
    };
}

fn decodeBytes(reader: *BufferReader) err.CallError![]const u8 {
    const len = try reader.readI32();
    if (len < 0) {
        return error.UnexpectedRustBufferData;
    }
    return reader.readSlice(@intCast(len));
}

fn decodeCloseReason(reader: *BufferReader) err.CallError!err.CloseReason {
    return switch (try reader.readI32()) {
        1 => .clean,
        2 => .fenced,
        3 => .background_panic,
        4 => .unknown,
        else => error.UnexpectedEnumTag,
    };
}
