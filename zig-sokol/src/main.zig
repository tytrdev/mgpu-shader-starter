const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;

const c = @cImport({
    @cInclude("OpenGL/gl3.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("crt_externs.h");
});

const vs_source =
    \\#version 410
    \\void main() {
    \\    vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
    \\    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    \\}
;

const fs_source =
    \\#version 410
    \\uniform vec3 iResolution;
    \\uniform float iTime;
    \\uniform vec4 iMouse;
    \\uniform float iTimeDelta;
    \\uniform int iFrame;
    \\out vec4 frag_color;
    \\void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    \\    vec2 uv = fragCoord/iResolution.xy;
    \\    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    \\    fragColor = vec4(col,1.0);
    \\}
    \\void main() {
    \\    mainImage(frag_color, gl_FragCoord.xy);
    \\}
;

// std140 layout, must match the glsl_uniforms reflection below.
const Params = extern struct {
    i_resolution: [3]f32,
    i_time: f32,
    i_mouse: [4]f32,
    i_time_delta: f32,
    i_frame: i32,
    _pad: [2]f32 = .{ 0, 0 },
};

var state: struct {
    pip: sg.Pipeline = .{},
    pass_action: sg.PassAction = .{},
    frame: i32 = 0,
    time: f32 = 0,
    mouse: [4]f32 = .{ 0, 0, 0, 0 },
} = .{};

var headless = false;
var out_res: i32 = 256;
var out_file: [*c]const u8 = "frame.ppm";

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    var shd_desc = sg.ShaderDesc{};
    shd_desc.vertex_func.source = vs_source;
    shd_desc.fragment_func.source = fs_source;
    shd_desc.uniform_blocks[0] = .{
        .stage = .FRAGMENT,
        .size = @sizeOf(Params),
        .layout = .STD140,
        .glsl_uniforms = blk: {
            var u = [_]sg.GlslShaderUniform{.{}} ** 16;
            u[0] = .{ .type = .FLOAT3, .array_count = 1, .glsl_name = "iResolution" };
            u[1] = .{ .type = .FLOAT, .array_count = 1, .glsl_name = "iTime" };
            u[2] = .{ .type = .FLOAT4, .array_count = 1, .glsl_name = "iMouse" };
            u[3] = .{ .type = .FLOAT, .array_count = 1, .glsl_name = "iTimeDelta" };
            u[4] = .{ .type = .INT, .array_count = 1, .glsl_name = "iFrame" };
            break :blk u;
        },
    };
    const shd = sg.makeShader(shd_desc);

    state.pip = sg.makePipeline(.{ .shader = shd });
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };
}

fn draw(w: f32, h: f32, t: f32, dt: f32) void {
    var p = Params{
        .i_resolution = .{ w, h, 1 },
        .i_time = t,
        .i_mouse = state.mouse,
        .i_time_delta = dt,
        .i_frame = state.frame,
    };
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyUniforms(0, sg.asRange(&p));
    sg.draw(0, 3, 1);
    sg.endPass();
    sg.commit();
}

export fn frame() void {
    if (headless) {
        const r: f32 = @floatFromInt(out_res);
        draw(r, r, 0, 0);
        readback();
        sapp.quit();
        return;
    }
    const w: f32 = @floatFromInt(sapp.width());
    const h: f32 = @floatFromInt(sapp.height());
    const dt: f32 = @floatCast(sapp.frameDuration());
    state.time += dt;
    draw(w, h, state.time, dt);
    state.frame += 1;
}

export fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    if (e.type == .MOUSE_MOVE) {
        state.mouse[0] = e.mouse_x;
        state.mouse[1] = @as(f32, @floatFromInt(sapp.height())) - e.mouse_y;
    }
}

export fn cleanup() void {
    sg.shutdown();
}

fn readback() void {
    if (sg.queryBackend() != .GLCORE) return;
    const res: c_int = out_res;
    const w: usize = @intCast(out_res);
    const raw = c.malloc(w * w * 4) orelse return;
    defer c.free(raw);
    c.glReadPixels(0, 0, res, res, c.GL_RGBA, c.GL_UNSIGNED_BYTE, raw);
    const buf: [*]u8 = @ptrCast(raw);

    const f = c.fopen(out_file, "wb") orelse return;
    defer _ = c.fclose(f);
    _ = c.fprintf(f, "P6\n%d %d\n255\n", res, res);
    // glReadPixels is bottom-first; PPM is top-first.
    var row: usize = 0;
    while (row < w) : (row += 1) {
        const src = (w - 1 - row) * w * 4;
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const ptr: *const anyopaque = @ptrCast(buf + src + x * 4);
            _ = c.fwrite(ptr, 1, 3, f);
        }
    }
}

pub fn main() void {
    const argc = c._NSGetArgc().*;
    const argv = c._NSGetArgv().*;
    if (argc >= 4 and std.mem.eql(u8, std.mem.span(argv[1]), "render")) {
        headless = true;
        out_res = std.fmt.parseInt(i32, std.mem.span(argv[2]), 10) catch 256;
        out_file = argv[3];
    }
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = event,
        .cleanup_cb = cleanup,
        .width = out_res,
        .height = out_res,
        .high_dpi = false,
        .window_title = "zig-sokol",
        .logger = .{ .func = slog.func },
    });
}
