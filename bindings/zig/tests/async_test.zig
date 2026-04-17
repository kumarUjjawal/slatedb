const std = @import("std");
const support = @import("support.zig");

test "Db async lifecycle and CRUD" {
    var runtime = support.AsyncRuntime.init();
    defer runtime.deinit();
    const io = runtime.io();

    var test_db = try support.TestDb.initAsync(io);
    defer test_db.deinit();

    try test_db.db.status();

    var put_future = test_db.db.put(io, "hello", "world");
    const write_handle = try put_future.await(io);
    try std.testing.expect(write_handle.seqnum > 0);
    try std.testing.expect(write_handle.create_ts > 0);

    var get_future = test_db.db.get(io, std.testing.allocator, "hello");
    const value = try get_future.await(io);
    defer if (value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(value != null);
    try std.testing.expectEqualSlices(u8, "world", value.?);

    var delete_future = test_db.db.delete(io, "hello");
    const delete_handle = try delete_future.await(io);
    try std.testing.expect(delete_handle.seqnum >= write_handle.seqnum);

    var deleted_get_future = test_db.db.get(io, std.testing.allocator, "hello");
    const deleted_value = try deleted_get_future.await(io);
    defer if (deleted_value) |bytes| std.testing.allocator.free(bytes);
    try std.testing.expect(deleted_value == null);

    try test_db.shutdownAsync(io);
    var closed_put_future = test_db.db.put(io, "after-shutdown", "value");
    try std.testing.expectError(error.Closed, closed_put_future.await(io));
}

test "Db async missing key and empty value" {
    var runtime = support.AsyncRuntime.init();
    defer runtime.deinit();
    const io = runtime.io();

    var test_db = try support.TestDb.initAsync(io);
    defer test_db.deinit();

    var put_future = test_db.db.put(io, "empty", "");
    _ = try put_future.await(io);

    var empty_get_future = test_db.db.get(io, std.testing.allocator, "empty");
    const empty_value = try empty_get_future.await(io);
    defer if (empty_value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(empty_value != null);
    try std.testing.expectEqual(@as(usize, 0), empty_value.?.len);

    var missing_get_future = test_db.db.get(io, std.testing.allocator, "missing");
    const missing_value = try missing_get_future.await(io);
    defer if (missing_value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(missing_value == null);
    try test_db.shutdownAsync(io);
}

test "Db async rejects empty keys" {
    var runtime = support.AsyncRuntime.init();
    defer runtime.deinit();
    const io = runtime.io();

    var test_db = try support.TestDb.initAsync(io);
    defer test_db.deinit();

    var invalid_put_future = test_db.db.put(io, "", "value");
    try std.testing.expectError(error.Invalid, invalid_put_future.await(io));

    var invalid_delete_future = test_db.db.delete(io, "");
    try std.testing.expectError(error.Invalid, invalid_delete_future.await(io));
    try test_db.shutdownAsync(io);
}
