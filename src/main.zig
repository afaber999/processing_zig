const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const Processing = @import("processing.zig");
//const Sketch = @import("examples/noc_1_1.zig");
const Sketch = @import("examples/noc_1_2.zig");

var blowup: bool = false;
var screenshot: bool = false;
var premult: bool = false;

fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, c.GL_TRUE);
    if (key == c.GLFW_KEY_SPACE and action == c.GLFW_PRESS)
        blowup = !blowup;
    if (key == c.GLFW_KEY_S and action == c.GLFW_PRESS)
        screenshot = true;
    if (key == c.GLFW_KEY_P and action == c.GLFW_PRESS)
        premult = !premult;
}

pub fn main() !void {
    var window: ?*c.GLFWwindow = null;
    var prevt: f64 = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;

    if (c.glfwInit() == c.GLFW_FALSE) {
        return error.GLFWInitFailed;
    }
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 2);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 0);

    const monitor = c.glfwGetPrimaryMonitor();
    var scale: f32 = 1;
    if (!builtin.target.isDarwin()) {
        c.glfwGetMonitorContentScale(monitor, &scale, null);
    }
    window = c.glfwCreateWindow(@floatToInt(i32, scale * 800), @floatToInt(i32, scale * 600), "ZIG processing", null, null);
    if (window == null) {
        return error.GLFWInitFailed;
    }
    defer c.glfwDestroyWindow(window);

    _ = c.glfwSetKeyCallback(window, keyCallback);

    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGL() == 0) {
        return error.GLADInitFailed;
    }

    var win_width: i32 = undefined;
    var win_height: i32 = undefined;
    c.glfwGetWindowSize(window, &win_width, &win_height);
    var processing: Processing = Processing.create(win_width, win_height);
    try processing.init(allocator);
    defer processing.deinit();

    c.glfwSwapInterval(0);

    c.glfwSetTime(0);
    prevt = c.glfwGetTime();

    var sketch = try allocator.create(Sketch);
    try sketch.setup(&processing);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        const t = c.glfwGetTime();
        const dt = t - prevt;
        _ = dt;
        prevt = t;

        var mx: f64 = undefined;
        var my: f64 = undefined;
        c.glfwGetCursorPos(window, &mx, &my);

        processing.update_mouse(@floatToInt(i32, mx), @floatToInt(i32, my));

        mx /= scale;
        my /= scale;

        //std.debug.print("Mouse pos {} {} \n ", .{ mx, my });

        c.glfwGetWindowSize(window, &win_width, &win_height);
        win_width = @floatToInt(i32, @intToFloat(f32, win_width) / scale);
        win_height = @floatToInt(i32, @intToFloat(f32, win_height) / scale);
        var fb_width: i32 = undefined;
        var fb_height: i32 = undefined;
        c.glfwGetFramebufferSize(window, &fb_width, &fb_height);

        // Calculate pixel ratio for hi-dpi devices.
        const px_ratio = @intToFloat(f32, fb_width) / @intToFloat(f32, win_width);

        // Update and render
        c.glViewport(0, 0, fb_width, fb_height);
        if (premult) {
            c.glClearColor(0, 0, 0, 0);
        } else {
            c.glClearColor(0.3, 0.3, 0.32, 1.0);
        }
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);

        // draw
        processing.begin_draw(win_width, win_height, px_ratio);

        try sketch.draw(&processing);

        //processing.draw(@floatCast(f32, mx), @floatCast(f32, my), @intToFloat(f32, win_width), @intToFloat(f32, win_height), @floatCast(f32, t), blowup);
        processing.end_draw();

        // if (screenshot) {
        //     screenshot = false;
        //     const data = try Processing.saveScreenshot(allocator, fb_width, fb_height, premult);
        //     defer allocator.free(data);
        //     try std.fs.cwd().writeFile("dump.png", data);
        // }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
        std.time.sleep(std.time.ns_per_ms * 16);
    }
}
