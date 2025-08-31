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

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "mmutil-zig",
        .target = target,
        .optimize = optimize,
    });

    // Add all C source files from the mmutil 'source' directory
    const source_dir = mmutil_dep.path("source");

    exe.addCSourceFiles(.{
        .root = source_dir,
        .files = &c_sources,
        .flags = &.{
            "-std=gnu11",
            "-Wall",
            "-Wextra",
            "-Wno-multichar",
            "-Wno-unused-but-set-variable",
            "-Wno-sign-compare",
            "-O3",
            "-DVERSION_ID=\"" ++ version ++ "\"",
        },
    });

    exe.addIncludePath(source_dir);

    // Add system libraries - match exactly what the Makefile does
    exe.linkSystemLibrary("m"); // math library
    exe.linkLibC();

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
