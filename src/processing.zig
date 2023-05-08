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
    self.m_translate = Vector2.create(0, 0);

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

pub fn line(self: *Self, a: f32, b: f32, c: f32, d: f32) void {
    self.m_vg.save();
    defer self.m_vg.restore();

    self.do_start();
    self.m_vg.moveTo(a, b);
    self.m_vg.lineTo(c, d);
    self.do_fill_stroke();
}
