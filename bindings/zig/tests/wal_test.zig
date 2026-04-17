const std = @import("std");
const slatedb = @import("slatedb");
const support = @import("support.zig");

test "WalReader empty store" {
    var store = try slatedb.ObjectStore.resolve("memory:///");
    defer store.deinit();

    var reader = try slatedb.WalReader.init(support.test_db_path, &store);
    defer reader.deinit();

    const files = try reader.listBlocking(std.testing.allocator, null, null);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, files);

    try std.testing.expectEqual(@as(usize, 0), files.len);
}

test "WalReader listing and navigation" {
    var store = try slatedb.ObjectStore.resolve("memory:///");
    defer store.deinit();

    try seedWalFiles(&store);

    var reader = try slatedb.WalReader.init(support.test_db_path, &store);
    defer reader.deinit();

    const files = try reader.listBlocking(std.testing.allocator, null, null);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, files);

    try std.testing.expect(files.len >= 3);

    var ids = try std.testing.allocator.alloc(u64, files.len);
    defer std.testing.allocator.free(ids);

    for (files, 0..) |*file, index| {
        ids[index] = try file.id();
        if (index > 0) {
            try std.testing.expect(ids[index] > ids[index - 1]);
        }
    }

    const start_id = ids[1];
    const end_id = ids[2];
    const bounded = try reader.listBlocking(std.testing.allocator, start_id, end_id);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, bounded);
    try std.testing.expectEqual(@as(usize, 1), bounded.len);
    try std.testing.expectEqual(ids[1], try bounded[0].id());

    const past_high_id = ids[ids.len - 1] + 1000;
    const empty = try reader.listBlocking(std.testing.allocator, past_high_id, null);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, empty);
    try std.testing.expectEqual(@as(usize, 0), empty.len);

    var first = try reader.get(ids[0]);
    defer first.deinit();
    try std.testing.expectEqual(ids[0], try first.id());
    try std.testing.expectEqual(ids[1], try first.nextId());

    var next = try first.nextFile();
    defer next.deinit();
    try std.testing.expectEqual(ids[1], try next.id());
}

test "WalReader metadata and rows" {
    var store = try slatedb.ObjectStore.resolve("memory:///");
    defer store.deinit();

    try seedWalFiles(&store);

    var reader = try slatedb.WalReader.init(support.test_db_path, &store);
    defer reader.deinit();

    const files = try reader.listBlocking(std.testing.allocator, null, null);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, files);

    try std.testing.expect(files.len >= 3);

    var all_rows = std.ArrayList(slatedb.RowEntry).empty;
    defer {
        for (all_rows.items) |*row| {
            row.deinit(std.testing.allocator);
        }
        all_rows.deinit(std.testing.allocator);
    }

    for (files, 0..) |*file, file_index| {
        var metadata = try file.metadataBlocking(std.testing.allocator);
        defer metadata.deinit(std.testing.allocator);

        try std.testing.expect(metadata.size_bytes > 0);
        try std.testing.expect(metadata.location.len > 0);
        _ = file_index;

        var iter = try file.iteratorBlocking();
        defer iter.deinit();

        while (try iter.nextBlocking(std.testing.allocator)) |row| {
            try std.testing.expect(row.seq > 0);
            try all_rows.append(std.testing.allocator, row);
        }
    }

    try std.testing.expectEqual(@as(usize, 4), all_rows.items.len);
    try expectRow(&all_rows.items[0], .value, "a", "1");
    try expectRow(&all_rows.items[1], .value, "b", "2");
    try expectRow(&all_rows.items[2], .tombstone, "a", null);
    try expectRow(&all_rows.items[3], .value, "c", "3");
}

test "WalReader missing file metadata fails" {
    var store = try slatedb.ObjectStore.resolve("memory:///");
    defer store.deinit();

    try seedWalFiles(&store);

    var reader = try slatedb.WalReader.init(support.test_db_path, &store);
    defer reader.deinit();

    const files = try reader.listBlocking(std.testing.allocator, null, null);
    defer slatedb.WalFile.deinitSlice(std.testing.allocator, files);

    try std.testing.expect(files.len > 0);

    const missing_id = try files[files.len - 1].id() + 1000;
    var missing = try reader.get(missing_id);
    defer missing.deinit();

    try std.testing.expectEqual(missing_id, try missing.id());

    if (missing.metadataBlocking(std.testing.allocator)) |metadata| {
        var value = metadata;
        value.deinit(std.testing.allocator);
        return error.TestUnexpectedResult;
    } else |_| {}
}

fn seedWalFiles(store: *slatedb.ObjectStore) !void {
    var builder = try slatedb.DbBuilder.init(support.test_db_path, store);
    defer builder.deinit();

    try builder.withWalObjectStore(store);

    var db = try builder.buildBlocking();
    defer db.deinit();

    _ = try db.putBlocking("a", "1");
    _ = try db.putBlocking("b", "2");
    try db.flushWithOptionsBlocking(.{ .flush_type = .wal });

    _ = try db.deleteBlocking("a");
    try db.flushWithOptionsBlocking(.{ .flush_type = .wal });

    _ = try db.putBlocking("c", "3");
    try db.flushWithOptionsBlocking(.{ .flush_type = .wal });

    try db.shutdownBlocking();
}

fn expectRow(
    row: *const slatedb.RowEntry,
    kind: slatedb.RowEntryKind,
    key: []const u8,
    value: ?[]const u8,
) !void {
    try std.testing.expectEqual(kind, row.kind);
    try std.testing.expectEqualSlices(u8, key, row.key);

    if (value) |expected| {
        try std.testing.expect(row.value != null);
        try std.testing.expectEqualSlices(u8, expected, row.value.?);
    } else {
        try std.testing.expect(row.value == null);
    }
}
