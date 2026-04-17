const slatedb = @import("slatedb");

pub const test_db_path = "test-db";

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

    pub fn shutdown(self: *TestDb) !void {
        try self.db.shutdownBlocking();
    }

    pub fn deinit(self: *TestDb) void {
        self.db.deinit();
        self.builder.deinit();
        self.store.deinit();
    }
};
