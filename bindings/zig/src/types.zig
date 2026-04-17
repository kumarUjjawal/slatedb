const std = @import("std");

pub const WriteHandle = struct {
    seqnum: u64,
    create_ts: i64,
};

pub const KeyRange = struct {
    start: ?[]const u8 = null,
    start_inclusive: bool = false,
    end: ?[]const u8 = null,
    end_inclusive: bool = false,
};

pub const KeyValue = struct {
    key: []u8,
    value: []u8,
    seq: u64,
    create_ts: i64,
    expire_ts: ?i64,

    pub fn deinit(self: *KeyValue, allocator: std.mem.Allocator) void {
        allocator.free(self.key);
        allocator.free(self.value);
        self.* = undefined;
    }
};
