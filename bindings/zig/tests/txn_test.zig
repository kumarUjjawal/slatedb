const std = @import("std");
const slatedb = @import("slatedb");
const support = @import("support.zig");

test "Db async transactions commit and rollback" {
    var runtime = support.AsyncRuntime.init();
    defer runtime.deinit();
    const io = runtime.io();

    var test_db = try support.TestDb.initAsync(io);
    defer test_db.deinit();

    var begin_future = test_db.db.begin(io, .snapshot);
    var tx = try begin_future.await(io);
    defer tx.deinit();

    const tx_seqnum = try tx.seqnum();

    const tx_id = try tx.id(std.testing.allocator);
    defer std.testing.allocator.free(tx_id);
    try std.testing.expect(tx_id.len > 0);

    var tx_put_future = tx.put(io, "txn-key", "pending");
    try tx_put_future.await(io);

    var tx_get_future = tx.get(io, std.testing.allocator, "txn-key");
    const tx_value = try tx_get_future.await(io);
    defer if (tx_value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(tx_value != null);
    try std.testing.expectEqualSlices(u8, "pending", tx_value.?);

    var live_before_future = test_db.db.get(io, std.testing.allocator, "txn-key");
    const live_before_value = try live_before_future.await(io);
    defer if (live_before_value) |bytes| std.testing.allocator.free(bytes);
    try std.testing.expect(live_before_value == null);

    var commit_future = tx.commit(io);
    const commit_handle = try commit_future.await(io);
    try std.testing.expect(commit_handle != null);
    try std.testing.expect(commit_handle.?.seqnum > 0);
    try std.testing.expect(commit_handle.?.seqnum >= tx_seqnum);

    var live_after_future = test_db.db.get(io, std.testing.allocator, "txn-key");
    const live_after_value = try live_after_future.await(io);
    defer if (live_after_value) |bytes| std.testing.allocator.free(bytes);

    try std.testing.expect(live_after_value != null);
    try std.testing.expectEqualSlices(u8, "pending", live_after_value.?);

    var begin_rollback_future = test_db.db.begin(io, slatedb.IsolationLevel.snapshot);
    var rollback_tx = try begin_rollback_future.await(io);
    defer rollback_tx.deinit();

    var rollback_put_future = rollback_tx.put(io, "rolled-back", "value");
    try rollback_put_future.await(io);

    var rollback_future = rollback_tx.rollback(io);
    try rollback_future.await(io);

    var rolled_back_get_future = test_db.db.get(io, std.testing.allocator, "rolled-back");
    const rolled_back_value = try rolled_back_get_future.await(io);
    defer if (rolled_back_value) |bytes| std.testing.allocator.free(bytes);
    try std.testing.expect(rolled_back_value == null);

    try test_db.shutdownAsync(io);
}
