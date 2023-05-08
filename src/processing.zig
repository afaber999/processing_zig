const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Vector2 = @import("vector2.zig");

// const c = @cImport({
//     @cDefine("STBI_WRITE_NO_STDIO", "1");
//     @cInclude("stb_image_write.h");
// });

m_vg: nvg = undefined,

m_fill_color: [4]u8 = [_]u8{ 0xff, 0xff, 0xff, 0xff },
m_no_fill: bool = false,

m_stroke_color: [4]u8 = [_]u8{ 0, 0, 0, 0xff },
m_no_stroke: bool = false,

m_translate: Vector2 = Vector2.create(0, 0),
m_no_translate: bool = true,

m_stroke_weight: i32 = 1,
m_width: i32,
m_height: i32,

m_mouse_x: i32 = 0,
m_mouse_y: i32 = 0,

m_pmouse_x: i32 = 0,
m_pmouse_y: i32 = 0,

window: ?*glfw.GLFWwindow,
setup_completed: bool = false,

pub fn mouse_x(self: *Self) i32 {
    return self.m_mouse_x;
}
pub fn mouse_y(self: *Self) i32 {
    return self.m_mouse_y;
}
pub fn pmouse_x(self: *Self) i32 {
    return self.m_pmouse_x;
}
pub fn pmouse_y(self: *Self) i32 {
    return self.m_pmouse_y;
}

pub fn update_mouse(self: *Self, nx: i32, ny: i32) void {
    self.m_pmouse_x = self.m_mouse_x;
    self.m_pmouse_y = self.m_mouse_y;
    self.m_mouse_x = nx;
    self.m_mouse_y = ny;
}
// const use_webgl = builtin.cpu.arch.isWasm();

// const gl = if (use_webgl)
//     @import("web/webgl.zig")
// else
//     @cImport({
//         @cInclude("glad/glad.h");
//     });
pub const gl = @cImport({
    @cInclude("glad/glad.h");
});

pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const nvg = @import("nanovg");

const Self = @This();

fn isBlack(col: nvg.Color) bool {
    return col.r == 0 and col.g == 0 and col.b == 0 and col.a == 0;
}

pub fn create(window: ?*glfw.GLFWwindow) Self {
    var win_width: i32 = undefined;
    var win_height: i32 = undefined;

    glfw.glfwGetWindowSize(window, &win_width, &win_height);

    return Self{
        .window = window,
        .m_width = win_width,
        .m_height = win_height,
    };
}

pub fn size(self: *Self, win_width: i32, win_height: i32) void {
    glfw.glfwSetWindowSize(self.window, win_width, win_height);
    var fb_width: i32 = undefined;
    var fb_height: i32 = undefined;
    glfw.glfwGetFramebufferSize(self.window, &fb_width, &fb_height);

    self.m_width = fb_width;
    self.m_height = fb_height;

    if (!self.setup_completed) {
        self.end_draw();
        self.begin_draw();
    }
}

pub fn init(self: *Self, allocator: Allocator) !void {
    self.m_vg = try nvg.gl.init(allocator, .{
        .antialias = true,
        .stencil_strokes = false,
        .debug = true,
    });
}

pub fn deinit(processing: Self) void {
    _ = processing;
}

pub fn begin_draw(self: *Self) void {

    // Calculate pixel ratio for hi-dpi devices.
    const px_ratio = @intToFloat(f32, self.m_width) / @intToFloat(f32, self.m_height);
    glfw.glViewport(0, 0, self.m_width, self.m_height);

    //c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
    gl.glClear(gl.GL_DEPTH_BUFFER_BIT | gl.GL_STENCIL_BUFFER_BIT);
    self.m_vg.beginFrame(@intToFloat(f32, self.m_width), @intToFloat(f32, self.m_height), px_ratio);
}

pub fn end_draw(self: *Self) void {
    self.m_vg.endFrame();
}

pub fn draw(self: *Self, mx: f32, my: f32, ww: f32, wh: f32, t: f32, blowup: bool) void {
    _ = blowup;

    drawEyes(self.m_vg, ww - 250, 50, 150, 100, mx, my, t);
    drawLines(self.m_vg, 120, wh - 50, 600, 50, t);
    drawWidths(self.m_vg, 10, 50, 30);
}

pub fn width(self: *const Self) i32 {
    return self.m_width;
}

pub fn height(self: *const Self) i32 {
    return self.m_height;
}

fn norm_color(color: u8) f32 {
    return @intToFloat(f32, color) / 255.0;
}

pub fn background(self: *Self, r: u8, g: u8, b: u8, a: u8) void {
    _ = self;
    gl.glClearColor(norm_color(r), norm_color(g), norm_color(b), norm_color(a));
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    // _ = sdl.SDL_SetRenderDrawColor(self.m_renderer, r, g, b, 0xff);
    // _ = sdl.SDL_RenderClear(self.m_renderer);
}

pub fn background_grey(self: *Self, col: u8) void {
    self.background_grey_alpha(col, 255);
}

pub fn background_grey_alpha(self: *Self, col: u8, a: u8) void {
    self.background(col, col, col, a);
}

pub fn translate(self: *Self, x: f32, y: f32) void {
    self.m_translate = Vector2.add(self.m_translate, Vector2.create(x, y));
    self.m_no_translate = false;
}

pub fn no_translate(self: *Self) void {
    self.m_tramslate = Vector2.create(0, 0);
    self.m_no_translate = true;
}

pub fn fill(self: *Self, r: u8, g: u8, b: u8, a: u8) void {
    self.m_fill_color[0] = r;
    self.m_fill_color[1] = g;
    self.m_fill_color[2] = b;
    self.m_fill_color[3] = a;
    self.m_no_fill = false;
}

pub fn no_fill(self: *Self) void {
    self.m_no_fill = true;
}

pub fn stroke(self: *Self, r: u8, g: u8, b: u8, a: u8) void {
    self.m_stroke_color[0] = r;
    self.m_stroke_color[1] = g;
    self.m_stroke_color[2] = b;
    self.m_stroke_color[3] = a;
    self.m_no_stroke = false;
}

pub fn no_stroke(self: *Self) void {
    self.m_no_stroke = true;
}

pub fn stroke_weight(self: *Self, weight: i32) void {
    self.m_stroke_weight = weight;
}

fn do_start(self: *Self) void {
    self.m_vg.beginPath();
    if (!self.m_no_translate) {
        self.m_vg.translate(self.m_translate.x, self.m_translate.y);
    }
}

fn do_fill_stroke(self: *Self) void {
    if (!self.m_no_fill) {
        self.m_vg.fillColor(nvg.rgba(self.m_fill_color[0], self.m_fill_color[1], self.m_fill_color[2], self.m_fill_color[3]));
        self.m_vg.fill();
    }
    if (!self.m_no_stroke) {
        self.m_vg.strokeColor(nvg.rgba(self.m_stroke_color[0], self.m_stroke_color[1], self.m_stroke_color[2], self.m_stroke_color[3]));
        self.m_vg.strokeWidth(@intToFloat(f32, self.m_stroke_weight));
        self.m_vg.stroke();
    }
}

pub fn rect(self: *Self, a: f32, b: f32, c: f32, d: f32) void {
    // const xl = a - c;
    // const yt = b - d;
    // const xr = a + c;
    // const yb = b + d;

    self.m_vg.save();
    defer self.m_vg.restore();

    self.do_start();
    self.m_vg.rect(a, b, c, d);
    self.do_fill_stroke();
}

pub fn ellipse(self: *Self, a: f32, b: f32, c: f32, d: f32) void {
    self.m_vg.save();
    defer self.m_vg.restore();

    self.do_start();
    self.m_vg.ellipse(a, b, c / 2.0, d / 2.0);
    self.do_fill_stroke();
}

fn drawEyes(vg: nvg, x: f32, y: f32, w: f32, h: f32, mx: f32, my: f32, t: f32) void {
    const ex = w * 0.23;
    const ey = h * 0.5;
    const lx = x + ex;
    const ly = y + ey;
    const rx = x + w - ex;
    const ry = y + ey;
    const br = (if (ex < ey) ex else ey) * 0.5;
    const blink = 1 - std.math.pow(f32, @sin(t * 0.5), 200) * 0.8;

    var bg = vg.linearGradient(x, y + h * 0.5, x + w * 0.1, y + h, nvg.rgba(0, 0, 0, 32), nvg.rgba(0, 0, 0, 16));
    vg.beginPath();
    vg.ellipse(lx + 3.0, ly + 16.0, ex, ey);
    vg.ellipse(rx + 3.0, ry + 16.0, ex, ey);
    vg.fillPaint(bg);
    vg.fill();

    bg = vg.linearGradient(x, y + h * 0.25, x + w * 0.1, y + h, nvg.rgba(220, 220, 220, 255), nvg.rgba(128, 128, 128, 255));
    vg.beginPath();
    vg.ellipse(lx, ly, ex, ey);
    vg.ellipse(rx, ry, ex, ey);
    vg.fillPaint(bg);
    vg.fill();

    var dx = (mx - rx) / (ex * 10);
    var dy = (my - ry) / (ey * 10);
    var d = @sqrt(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    vg.beginPath();
    vg.ellipse(lx + dx, ly + dy + ey * 0.25 * (1 - blink), br, br * blink);
    vg.fillColor(nvg.rgba(32, 32, 32, 255));
    vg.fill();

    dx = (mx - rx) / (ex * 10);
    dy = (my - ry) / (ey * 10);
    d = @sqrt(dx * dx + dy * dy);
    if (d > 1.0) {
        dx /= d;
        dy /= d;
    }
    dx *= ex * 0.4;
    dy *= ey * 0.5;
    vg.beginPath();
    vg.ellipse(rx + dx, ry + dy + ey * 0.25 * (1 - blink), br, br * blink);
    vg.fillColor(nvg.rgba(32, 32, 32, 255));
    vg.fill();

    var gloss = vg.radialGradient(lx - ex * 0.25, ly - ey * 0.5, ex * 0.1, ex * 0.75, nvg.rgba(255, 255, 255, 128), nvg.rgba(255, 255, 255, 0));
    vg.beginPath();
    vg.ellipse(lx, ly, ex, ey);
    vg.fillPaint(gloss);
    vg.fill();

    gloss = vg.radialGradient(rx - ex * 0.25, ry - ey * 0.5, ex * 0.1, ex * 0.75, nvg.rgba(255, 255, 255, 128), nvg.rgba(255, 255, 255, 0));
    vg.beginPath();
    vg.ellipse(rx, ry, ex, ey);
    vg.fillPaint(gloss);
    vg.fill();
}

fn drawLines(vg: nvg, x: f32, y: f32, w: f32, h: f32, t: f32) void {
    _ = h;
    const pad = 5.0;
    const s = w / 9.0 - pad * 2.0;
    const joins = [_]nvg.LineJoin{ .miter, .round, .bevel };
    const caps = [_]nvg.LineCap{ .butt, .round, .square };
    const pts = [_]f32{
        -s * 0.25 + @cos(t * 0.3) * s * 0.5, @sin(t * 0.3) * s * 0.5,
        -s * 0.25,                           0,
        s * 0.25,                            0,
        s * 0.25 + @cos(-t * 0.3) * s * 0.5, @sin(-t * 0.3) * s * 0.5,
    };

    vg.save();
    defer vg.restore();

    for (caps, 0..) |cap, i| {
        for (joins, 0..) |join, j| {
            const fx = x + s * 0.5 + (@intToFloat(f32, i) * 3 + @intToFloat(f32, j)) / 9.0 * w + pad;
            const fy = y - s * 0.5 + pad;

            vg.lineCap(cap);
            vg.lineJoin(join);

            vg.strokeWidth(s * 0.3);
            vg.strokeColor(nvg.rgba(0, 0, 0, 160));
            vg.beginPath();
            vg.moveTo(fx + pts[0], fy + pts[1]);
            vg.lineTo(fx + pts[2], fy + pts[3]);
            vg.lineTo(fx + pts[4], fy + pts[5]);
            vg.lineTo(fx + pts[6], fy + pts[7]);
            vg.stroke();

            vg.lineCap(.butt);
            vg.lineJoin(.bevel);

            vg.strokeWidth(1.0);
            vg.strokeColor(nvg.rgba(0, 192, 255, 255));
            vg.beginPath();
            vg.moveTo(fx + pts[0], fy + pts[1]);
            vg.lineTo(fx + pts[2], fy + pts[3]);
            vg.lineTo(fx + pts[4], fy + pts[5]);
            vg.lineTo(fx + pts[6], fy + pts[7]);
            vg.stroke();
        }
    }
}

fn drawWidths(vg: nvg, x: f32, y0: f32, ww: f32) void {
    vg.save();
    defer vg.restore();

    vg.strokeColor(nvg.rgba(0, 0, 0, 255));

    var y = y0;
    var i: usize = 0;
    while (i < 20) : (i += 1) {
        const w = (@intToFloat(f32, i) + 0.5) * 0.1;
        vg.strokeWidth(w);
        vg.beginPath();
        vg.moveTo(x, y);
        vg.lineTo(x + ww, y + ww * 0.3);
        vg.stroke();
        y += 10;
    }
}
