const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;

const gl = @cImport({
    @cInclude("OpenGL/gl3.h");
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
    \\layout(std140) uniform params {
    \\    vec3 iResolution;
    \\    float iTime;
    \\    vec4 iMouse;
    \\    float iTimeDelta;
    \\    int iFrame;
    \\};
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
    bind: sg.Bindings = .{},
    pass_action: sg.PassAction = .{},
    frame: i32 = 0,
    mouse: [4]f32 = .{ 0, 0, 0, 0 },
} = .{};

var headless = false;
var out_res: i32 = 256;
var out_file: []const u8 = "frame.ppm";

export fn init() void {
    sg.setup(.{ .environment = sglue.environment(), .logger = .{ .func = slog.func } });

    var shd_desc = sg.ShaderDesc{};
    shd_desc.vertex_func.source = vs_source;
    shd_desc.fragment_func.source = fs_source;
    shd_desc.uniform_blocks[0] = .{
        .stage = .FRAGMENT,
        .size = @sizeOf(Params),
        .layout = .STD140,
        .glsl_uniform_block_name = "params",
    };
    const shd = sg.makeShader(shd_desc);

    state.pip = sg.makePipeline(.{ .shader = shd });
    state.pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 } };
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
    const w: f32 = @floatFromInt(sapp.width());
    const h: f32 = @floatFromInt(sapp.height());
    if (headless) {
        draw(@floatFromInt(out_res), @floatFromInt(out_res), 0, 0);
        readback() catch {};
        sapp.quit();
        return;
    }
    const t: f32 = @floatCast(sapp.frameDuration() * @as(f64, @floatFromInt(state.frame)));
    draw(w, h, t, @floatCast(sapp.frameDuration()));
    state.frame += 1;
}

export fn event(ev: [*c]const sapp.Event) void {
    const e = ev.*;
    switch (e.type) {
        .MOUSE_MOVE => {
            state.mouse[0] = e.mouse_x;
            state.mouse[1] = @as(f32, @floatFromInt(sapp.height())) - e.mouse_y;
        },
        else => {},
    }
}

export fn cleanup() void {
    sg.shutdown();
}

fn readback() !void {
    if (sg.queryBackend() != .GLCORE) return error.NotGL;
    const res: usize = @intCast(out_res);
    const buf = try std.heap.page_allocator.alloc(u8, res * res * 4);
    defer std.heap.page_allocator.free(buf);
    gl.glReadPixels(0, 0, @intCast(res), @intCast(res), gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, buf.ptr);

    var f = try std.fs.cwd().createFile(out_file, .{});
    defer f.close();
    var w = f.writer();
    try w.print("P6\n{d} {d}\n255\n", .{ res, res });
    // glReadPixels is bottom-first; PPM is top-first.
    var row: usize = 0;
    while (row < res) : (row += 1) {
        const src = (res - 1 - row) * res * 4;
        var x: usize = 0;
        while (x < res) : (x += 1) {
            try w.writeAll(buf[src + x * 4 .. src + x * 4 + 3]);
        }
    }
}

pub fn main() void {
    var args = std.process.args();
    _ = args.skip();
    if (args.next()) |a| {
        if (std.mem.eql(u8, a, "render")) {
            headless = true;
            if (args.next()) |r| out_res = std.fmt.parseInt(i32, r, 10) catch 256;
            if (args.next()) |o| out_file = o;
        }
    }
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = event,
        .cleanup_cb = cleanup,
        .width = out_res,
        .height = out_res,
        .window_title = "zig-sokol",
        .logger = .{ .func = slog.func },
    });
}
