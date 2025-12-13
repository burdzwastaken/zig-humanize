const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const humanize_module = b.addModule("humanize", .{
        .root_source_file = b.path("src/humanize.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/humanize.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib_tests = b.addTest(.{
        .root_module = test_module,
    });
    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_lib_tests.step);

    addExample(b, target, optimize, humanize_module, "examples/basic.zig", "basic-example", "run-example", "Run the basic example");
}

fn addExample(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    humanize_module: *std.Build.Module,
    source_path: []const u8,
    exe_name: []const u8,
    step_name: []const u8,
    step_description: []const u8,
) void {
    const example_module = b.createModule(.{
        .root_source_file = b.path(source_path),
        .target = target,
        .optimize = optimize,
    });
    example_module.addImport("humanize", humanize_module);

    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_module = example_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step(step_name, step_description);
    run_step.dependOn(&run_cmd.step);
}
