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
    const constructor_writebatch_new = 25201;
    const method_dbbuilder_build = 57780;
    const method_db_delete = 34129;
    const method_db_get = 50068;
    const method_db_put = 59996;
    const method_db_shutdown = 43377;
    const method_db_status = 55824;
    const method_db_write = 13969;
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
        "uniffi_slatedb_uniffi_checksum_constructor_writebatch_new",
        checksums.constructor_writebatch_new,
        c.uniffi_slatedb_uniffi_checksum_constructor_writebatch_new(),
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
        "uniffi_slatedb_uniffi_checksum_method_db_shutdown",
        checksums.method_db_shutdown,
        c.uniffi_slatedb_uniffi_checksum_method_db_shutdown(),
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
