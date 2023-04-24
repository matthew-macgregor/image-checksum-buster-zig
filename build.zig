const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Zig executable
    const exe = b.addExecutable("izbuster", "src/zig/main.zig");
    exe.addPackagePath("image", "src/zig/image.zig");
    exe.addPackagePath("config", "src/zig/config.zig");
    exe.addPackagePath("ansi", "src/zig/ansi.zig");
    exe.addPackagePath("clap", "libs/zig-clap/clap.zig");
    exe.addIncludePath("libs");
    // -fno-sanitize=undefined: https://github.com/ziglang/zig/wiki/FAQ#why-do-i-get-illegal-instruction-when-using-with-zig-cc-to-build-c-code
    // stb_image has UB in stbi_write_jpg, and Clang treats this as illegal instruction in debug mode.
    exe.addCSourceFile("libs/stb_image/stbi_image.c", &.{ "-Wall", "-Wextra", "-Werror", "-std=c99", "-fno-sanitize=undefined" });
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run/zig", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/test.zig");
    exe_tests.addPackagePath("image", "src/zig/image.zig");
    exe_tests.addIncludePath("libs");
    // -fno-sanitize=undefined: https://github.com/ziglang/zig/wiki/FAQ#why-do-i-get-illegal-instruction-when-using-with-zig-cc-to-build-c-code
    // stb_image has UB in stbi_write_jpg, and Clang treats this as illegal instruction in debug mode.
    exe_tests.addCSourceFile("libs/stb_image/stbi_image.c", &.{ "-Wall", "-Wextra", "-Werror", "-std=c99", "-fno-sanitize=undefined" });

    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    // C executable
    const exe_c = b.addExecutable("icbuster", "src/c/main.c");
    exe_c.addCSourceFile("libs/stb_image/stbi_image.c", &.{ "-Wall", "-Wextra", "-Werror", "-std=c99", "-fno-sanitize=undefined" });
    exe_c.addCSourceFile("libs/cargs/cargs.c", &.{ "-Wall", "-Wextra", "-Werror", "-std=c11", "-fno-sanitize=undefined" });
    exe_c.addCSourceFile("src/c/image.c", &.{ "-Wall", "-Wextra", "-Werror", "-std=c99", "-fno-sanitize=undefined" });
    exe_c.addIncludePath("libs");
    exe_c.addIncludePath("src/c");
    exe_c.setTarget(target);
    exe_c.setBuildMode(mode);
    exe_c.install();

    const run_cmd_c = exe_c.run();
    run_cmd_c.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd_c.addArgs(args);
    }

    const run_step_c = b.step("run/c", "Run the app");
    run_step_c.dependOn(&run_cmd_c.step);
}
