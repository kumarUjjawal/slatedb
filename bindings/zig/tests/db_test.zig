const std = @import("std");
const support = @import("support.zig");

test "Db missing key read" {
    var test_db = try support.TestDb.init();
    defer test_db.deinit();

    const value = try test_db.db.getBlocking(std.testing.allocator, "missing");
    defer if (value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(value == null);
    try test_db.shutdown();
}

test "Db status after build" {
    var test_db = try support.TestDb.init();
    defer test_db.deinit();

    try test_db.db.status();
}

test "Db lifecycle and basic CRUD" {
    var test_db = try support.TestDb.init();
    defer test_db.deinit();

    try test_db.db.status();

    const write_handle = try test_db.db.putBlocking("hello", "world");
    try std.testing.expect(write_handle.seqnum > 0);
    try std.testing.expect(write_handle.create_ts > 0);

    const value = try test_db.db.getBlocking(std.testing.allocator, "hello");
    defer if (value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(value != null);
    try std.testing.expectEqualSlices(u8, "world", value.?);

    try test_db.shutdown();
    try std.testing.expectError(error.Closed, test_db.db.status());
    try std.testing.expectError(error.Closed, test_db.db.putBlocking("after-shutdown", "value"));
}

test "Db delete removes a value" {
    var test_db = try support.TestDb.init();
    defer test_db.deinit();

    _ = try test_db.db.putBlocking("delete-me", "value");

    const delete_handle = try test_db.db.deleteBlocking("delete-me");
    try std.testing.expect(delete_handle.seqnum > 0);
    try std.testing.expect(delete_handle.create_ts > 0);

    const value = try test_db.db.getBlocking(std.testing.allocator, "delete-me");
    defer if (value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(value == null);
    try test_db.shutdown();
}
