const std = @import("std");
const nanovg_build = @import("deps/nanovg-zig/build.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    const nanovg = b.createModule(.{ .source_file = .{ .path = "deps/nanovg-zig/src/nanovg.zig" } });

    const exe = b.addExecutable(.{
        .name = "processing_zig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const c_flags: []const []const u8 = if (optimize == .Debug)
        &.{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS", "-O0", "-g" }
    else
        &.{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS" };

    exe.addIncludePath("lib/gl2/include");
    exe.addCSourceFile("lib/gl2/src/glad.c", c_flags);

    // AF TODO MOVE TO LIB AS WELL
    exe.addIncludePath("lib/stb");
    exe.addCSourceFile("lib/stb/stb_image_write.c", &.{ "-DSTBI_NO_STDIO", "-fno-stack-protector" });

    exe.addModule("nanovg", nanovg);
    nanovg_build.addCSourceFiles(exe);

    if (target.isWindows()) {
        // artifact.addVcpkgPaths(.dynamic) catch @panic("vcpkg not installed");
        // if (artifact.vcpkg_bin_path) |bin_path| {
        //     for (&[_][]const u8{"glfw3.dll"}) |dll| {
        //         const src_dll = try std.fs.path.join(b.allocator, &.{ bin_path, dll });
        //         b.installBinFile(src_dll, dll);
        //     }
        // }

        const glfw_path = "D:\\zig\\glfw-3.3.8.bin.WIN64\\";
        exe.addIncludePath(glfw_path ++ "include");
        exe.addLibraryPath(glfw_path ++ "lib-static-ucrt");
        b.installBinFile(glfw_path ++ "lib-static-ucrt\\glfw3.dll", "glfw3.dll");

        //artifact.addIncludePath("D:\\zig\\glfw-3.3.8.bin.WIN64\\include");
        exe.linkSystemLibrary("glfw3dll");
        exe.linkSystemLibrary("opengl32");
    } else if (target.isDarwin()) {
        exe.linkSystemLibrary("glfw3");
        exe.linkFramework("OpenGL");
    } else if (target.isLinux()) {
        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("X11");
    } else {
        std.log.warn("Unsupported target: {}", .{target});
        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("GL");
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
