const std = @import("std");
const err = @import("error.zig");

pub const c = @cImport({
    @cInclude("slatedb.h");
});

const bindings_contract_version: u32 = 29;

var abi_checked = false;

const checksums = struct {
    const constructor_objectstore_resolve = 27737;
    const constructor_dbbuilder_new = 20774;
    const constructor_dbreaderbuilder_new = 63705;
    const constructor_writebatch_new = 25201;
    const method_db_begin = 51275;
    const method_dbbuilder_build = 57780;
    const method_db_delete = 34129;
    const method_db_get = 50068;
    const method_db_put = 59996;
    const method_dbreader_get = 22886;
    const method_dbreader_scan = 19575;
    const method_dbreader_scan_prefix = 51732;
    const method_dbreader_shutdown = 33391;
    const method_dbreaderbuilder_build = 3383;
    const method_db_scan = 38146;
    const method_db_scan_prefix = 16589;
    const method_db_shutdown = 43377;
    const method_db_snapshot = 13313;
    const method_db_status = 55824;
    const method_db_write = 13969;
    const method_dbiterator_next = 49160;
    const method_dbiterator_seek = 43547;
    const method_dbsnapshot_get = 37663;
    const method_dbtransaction_commit = 17358;
    const method_dbtransaction_get = 27661;
    const method_dbtransaction_id = 16876;
    const method_dbtransaction_put = 30341;
    const method_dbtransaction_rollback = 23348;
    const method_dbtransaction_seqnum = 60506;
    const method_writebatch_delete = 37032;
    const method_writebatch_put = 35694;
};

pub fn ensureCompatible() err.CallError!void {
    if (abi_checked) {
        return;
    }

    const contract_version = c.ffi_slatedb_uniffi_uniffi_contract_version();
    if (contract_version != bindings_contract_version) {
        std.log.err(
            "SlateDB UniFFI contract version mismatch: Zig expects {d}, dylib has {d}",
            .{ bindings_contract_version, contract_version },
        );
        return error.ContractVersionMismatch;
    }

    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_constructor_objectstore_resolve",
        checksums.constructor_objectstore_resolve,
        c.uniffi_slatedb_uniffi_checksum_constructor_objectstore_resolve(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_constructor_dbbuilder_new",
        checksums.constructor_dbbuilder_new,
        c.uniffi_slatedb_uniffi_checksum_constructor_dbbuilder_new(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_constructor_dbreaderbuilder_new",
        checksums.constructor_dbreaderbuilder_new,
        c.uniffi_slatedb_uniffi_checksum_constructor_dbreaderbuilder_new(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_constructor_writebatch_new",
        checksums.constructor_writebatch_new,
        c.uniffi_slatedb_uniffi_checksum_constructor_writebatch_new(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_begin",
        checksums.method_db_begin,
        c.uniffi_slatedb_uniffi_checksum_method_db_begin(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbbuilder_build",
        checksums.method_dbbuilder_build,
        c.uniffi_slatedb_uniffi_checksum_method_dbbuilder_build(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_delete",
        checksums.method_db_delete,
        c.uniffi_slatedb_uniffi_checksum_method_db_delete(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_get",
        checksums.method_db_get,
        c.uniffi_slatedb_uniffi_checksum_method_db_get(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_put",
        checksums.method_db_put,
        c.uniffi_slatedb_uniffi_checksum_method_db_put(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbreader_get",
        checksums.method_dbreader_get,
        c.uniffi_slatedb_uniffi_checksum_method_dbreader_get(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbreader_scan",
        checksums.method_dbreader_scan,
        c.uniffi_slatedb_uniffi_checksum_method_dbreader_scan(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbreader_scan_prefix",
        checksums.method_dbreader_scan_prefix,
        c.uniffi_slatedb_uniffi_checksum_method_dbreader_scan_prefix(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbreader_shutdown",
        checksums.method_dbreader_shutdown,
        c.uniffi_slatedb_uniffi_checksum_method_dbreader_shutdown(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbreaderbuilder_build",
        checksums.method_dbreaderbuilder_build,
        c.uniffi_slatedb_uniffi_checksum_method_dbreaderbuilder_build(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_scan",
        checksums.method_db_scan,
        c.uniffi_slatedb_uniffi_checksum_method_db_scan(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_scan_prefix",
        checksums.method_db_scan_prefix,
        c.uniffi_slatedb_uniffi_checksum_method_db_scan_prefix(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_shutdown",
        checksums.method_db_shutdown,
        c.uniffi_slatedb_uniffi_checksum_method_db_shutdown(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_snapshot",
        checksums.method_db_snapshot,
        c.uniffi_slatedb_uniffi_checksum_method_db_snapshot(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_status",
        checksums.method_db_status,
        c.uniffi_slatedb_uniffi_checksum_method_db_status(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_db_write",
        checksums.method_db_write,
        c.uniffi_slatedb_uniffi_checksum_method_db_write(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbsnapshot_get",
        checksums.method_dbsnapshot_get,
        c.uniffi_slatedb_uniffi_checksum_method_dbsnapshot_get(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbiterator_next",
        checksums.method_dbiterator_next,
        c.uniffi_slatedb_uniffi_checksum_method_dbiterator_next(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbiterator_seek",
        checksums.method_dbiterator_seek,
        c.uniffi_slatedb_uniffi_checksum_method_dbiterator_seek(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_commit",
        checksums.method_dbtransaction_commit,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_commit(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_get",
        checksums.method_dbtransaction_get,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_get(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_id",
        checksums.method_dbtransaction_id,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_id(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_put",
        checksums.method_dbtransaction_put,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_put(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_rollback",
        checksums.method_dbtransaction_rollback,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_rollback(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_dbtransaction_seqnum",
        checksums.method_dbtransaction_seqnum,
        c.uniffi_slatedb_uniffi_checksum_method_dbtransaction_seqnum(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_writebatch_delete",
        checksums.method_writebatch_delete,
        c.uniffi_slatedb_uniffi_checksum_method_writebatch_delete(),
    );
    try expectChecksum(
        "uniffi_slatedb_uniffi_checksum_method_writebatch_put",
        checksums.method_writebatch_put,
        c.uniffi_slatedb_uniffi_checksum_method_writebatch_put(),
    );

    abi_checked = true;
}

fn expectChecksum(name: []const u8, expected: u16, actual: anytype) err.CallError!void {
    const actual_value: u16 = @intCast(actual);
    if (actual_value != expected) {
        std.log.err(
            "{s} mismatch: Zig expects {d}, dylib has {d}",
            .{ name, expected, actual_value },
        );
        return error.ApiChecksumMismatch;
    }
}
