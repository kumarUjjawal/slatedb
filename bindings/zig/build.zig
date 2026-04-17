const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_dir_override = b.option([]const u8, "slatedb-lib-dir", "Path to the directory that contains libslatedb_uniffi");
    const default_lib_dir = switch (optimize) {
        .Debug => "../../target/debug",
        .ReleaseSafe, .ReleaseFast, .ReleaseSmall => "../../target/release",
    };
    const lib_dir = b.path(lib_dir_override orelse default_lib_dir);

    const slatedb_mod = b.addModule("slatedb", .{
        .root_source_file = b.path("src/slatedb.zig"),
        .target = target,
        .optimize = optimize,
    });
    configureModule(b, slatedb_mod, lib_dir);

    const tests_root = b.createModule(.{
        .root_source_file = b.path("tests/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "slatedb", .module = slatedb_mod },
        },
    });
    configureModule(b, tests_root, lib_dir);

    const unit_tests = b.addTest(.{
        .root_module = tests_root,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run Zig binding tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn configureModule(b: *std.Build, module: *std.Build.Module, lib_dir: std.Build.LazyPath) void {
    module.link_libc = true;
    module.addIncludePath(b.path("include"));
    module.addLibraryPath(lib_dir);
    module.addRPath(lib_dir);
    module.linkSystemLibrary("slatedb_uniffi", .{
        .preferred_link_mode = .dynamic,
        .use_pkg_config = .no,
    });
}
