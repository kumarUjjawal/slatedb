const std = @import("std");
const slatedb = @import("slatedb");

pub const test_db_path = "test-db";

pub const AsyncRuntime = struct {
    threaded: std.Io.Threaded,

    pub fn init() AsyncRuntime {
        return .{
            .threaded = std.Io.Threaded.init(std.heap.smp_allocator, .{}),
        };
    }

    pub fn io(self: *AsyncRuntime) std.Io {
        return self.threaded.io();
    }

    pub fn deinit(self: *AsyncRuntime) void {
        self.threaded.deinit();
    }
};

pub const TestDb = struct {
    store: slatedb.ObjectStore,
    builder: slatedb.DbBuilder,
    db: slatedb.Db,

    pub fn init() !TestDb {
        var store = try slatedb.ObjectStore.resolve("memory:///");
        errdefer store.deinit();

        var builder = try slatedb.DbBuilder.init(test_db_path, &store);
        errdefer builder.deinit();

        var db = try builder.buildBlocking();
        errdefer db.deinit();

        return .{
            .store = store,
            .builder = builder,
            .db = db,
        };
    }

    pub fn initAsync(io: std.Io) !TestDb {
        var store = try slatedb.ObjectStore.resolve("memory:///");
        errdefer store.deinit();

        var builder = try slatedb.DbBuilder.init(test_db_path, &store);
        errdefer builder.deinit();

        var build_future = builder.build(io);
        var db = try build_future.await(io);
        errdefer db.deinit();

        return .{
            .store = store,
            .builder = builder,
            .db = db,
        };
    }

    pub fn shutdown(self: *TestDb) !void {
        try self.db.shutdownBlocking();
    }

    pub fn shutdownAsync(self: *TestDb, io: std.Io) !void {
        var shutdown_future = self.db.shutdown(io);
        try shutdown_future.await(io);
    }

    pub fn deinit(self: *TestDb) void {
        self.db.deinit();
        self.builder.deinit();
        self.store.deinit();
    }
};
