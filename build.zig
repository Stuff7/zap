const std = @import("std");

const Module = std.Build.Module;
const Import = Module.Import;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bin_name = "zap";
    const suffix = switch (optimize) {
        .Debug => "-dbg",
        .ReleaseFast => "",
        .ReleaseSafe => "-s",
        .ReleaseSmall => "-sm",
    };

    const dep_zut = b.dependency("zut", .{ .target = target, .optimize = optimize });

    const zap = b.addModule("zap", .{
        .root_source_file = b.path("src/zap.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zut", .module = dep_zut.module("zut") },
        },
    });
    const main_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zut", .module = dep_zut.module("zut") },
            .{ .name = "zap", .module = zap },
        },
    });

    const exe = b.addExecutable(.{
        .name = b.fmt("{s}{s}", .{ bin_name, suffix }),
        .root_module = main_module,
    });
    b.installArtifact(exe);

    const tests = b.addTest(.{ .name = bin_name, .root_module = main_module });
    const run_tests = b.addRunArtifact(tests);
    b.step("test", "Run tests").dependOn(&run_tests.step);

    const check = b.addExecutable(.{ .name = "check", .root_module = main_module });
    const check_step = b.step("check", "Build for LSP");
    check_step.dependOn(&check.step);
    check_step.dependOn(&run_tests.step);
}
