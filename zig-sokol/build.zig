const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Force the GL backend so the headless test can read pixels with glReadPixels
    // and gl_FragCoord keeps the bottom-left origin.
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .gl = true,
    });

    const exe = b.addExecutable(.{
        .name = "zig-sokol",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
    exe.linkFramework("OpenGL");
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |a| run.addArgs(a);
    b.step("run", "Run the windowed starter").dependOn(&run.step);

    const render = b.addRunArtifact(exe);
    render.addArg("render");
    if (b.args) |a| render.addArgs(a);
    b.step("render", "Render one frame to a PPM").dependOn(&render.step);

    const test_step = b.step("test", "Render and assert against tools/ref.py");
    const py = b.addSystemCommand(&.{ "python3", "../tools/assert_frame.py", "frame.ppm" });
    py.step.dependOn(&render.step);
    test_step.dependOn(&py.step);
}
