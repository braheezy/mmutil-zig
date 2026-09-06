const std = @import("std");

const version = "1.13.1 (zig build)";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // If .Debug is used, mmutil build but fails to run.
    const optimize = std.builtin.OptimizeMode.ReleaseFast;

    // Get the mmutil dependency path
    const mmutil_dep = b.dependency("mmutil", .{
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "mmutil-zig",
        .root_module = exe_mod,
    });

    // Add all C source files from the mmutil 'source' directory
    const source_dir = mmutil_dep.path("source");
    const data_dir = mmutil_dep.path("data");

    exe_mod.addIncludePath(source_dir);
    exe_mod.addEmbedPath(data_dir);

    // Strict C23 hides mkstemp and asprintf in Linux libc headers unless
    // their feature set is explicitly enabled before including the headers.
    if (target.result.os.tag == .linux) {
        exe_mod.addCMacro("_GNU_SOURCE", "1");
    }

    exe_mod.addCSourceFiles(.{
        .root = source_dir,
        .files = &c_sources,
        .flags = &.{
            "-std=c23",
            "-Wall",
            "-Wextra",
            "-Wno-multichar",
            "-Wno-unused-but-set-variable",
            "-Wno-sign-compare",
            "-O3",
            "-DVERSION_STRING=\"" ++ version ++ "\"",
        },
    });

    // Add system libraries
    exe_mod.linkSystemLibrary("m", .{}); // math library

    // Install the executable
    b.installArtifact(exe);

    // Create a run step for testing
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run mmutil");
    run_step.dependOn(&run_cmd.step);
}

const c_sources = [_][]const u8{
    "adpcm.c",
    "files.c",
    "gba.c",
    "it.c",
    "main.c",
    "mas.c",
    "mod.c",
    "msl.c",
    "nds.c",
    "s3m.c",
    "samplefix.c",
    "simple.c",
    "wav.c",
    "xm.c",
};
