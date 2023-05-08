const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("glad/glad.h");
});

const glfw = Processing.glfw;

const Processing = @import("processing.zig");
const Sketch = @import("examples/noc_1_1.zig");
//const Sketch = @import("examples/noc_1_2.zig");

var blowup: bool = false;
var screenshot: bool = false;
var premult: bool = true;

fn keyCallback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    if (key == glfw.GLFW_KEY_ESCAPE and action == glfw.GLFW_PRESS)
        glfw.glfwSetWindowShouldClose(window, glfw.GL_TRUE);
    if (key == glfw.GLFW_KEY_SPACE and action == glfw.GLFW_PRESS)
        blowup = !blowup;
    if (key == glfw.GLFW_KEY_S and action == glfw.GLFW_PRESS)
        screenshot = true;
    if (key == glfw.GLFW_KEY_P and action == glfw.GLFW_PRESS)
        premult = !premult;
}

pub fn main() !void {
    var window: ?*glfw.GLFWwindow = null;
    var prevt: f64 = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;

    if (glfw.glfwInit() == glfw.GLFW_FALSE) {
        return error.GLFWInitFailed;
    }
    defer glfw.glfwTerminate();
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 0);

    const monitor = glfw.glfwGetPrimaryMonitor();
    var scale: f32 = 1;
    if (!builtin.target.isDarwin()) {
        glfw.glfwGetMonitorContentScale(monitor, &scale, null);
    }
    window = glfw.glfwCreateWindow(@floatToInt(i32, scale * 800), @floatToInt(i32, scale * 600), "ZIG processing", null, null);
    if (window == null) {
        return error.GLFWInitFailed;
    }
    defer glfw.glfwDestroyWindow(window);

    _ = glfw.glfwSetKeyCallback(window, keyCallback);

    glfw.glfwMakeContextCurrent(window);

    if (c.gladLoadGL() == 0) {
        return error.GLADInitFailed;
    }

    var processing: Processing = Processing.create(window);
    try processing.init(allocator);
    defer processing.deinit();

    glfw.glfwSwapInterval(0);

    glfw.glfwSetTime(0);
    prevt = glfw.glfwGetTime();

    var sketch = try allocator.create(Sketch);

    processing.begin_draw();
    try sketch.setup(&processing);
    processing.end_draw();
    processing.setup_completed = true;

    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        const t = glfw.glfwGetTime();
        const dt = t - prevt;
        _ = dt;
        prevt = t;

        var mx: f64 = undefined;
        var my: f64 = undefined;
        glfw.glfwGetCursorPos(window, &mx, &my);

        processing.update_mouse(@floatToInt(i32, mx), @floatToInt(i32, my));

        mx /= scale;
        my /= scale;

        //std.debug.print("Mouse pos {} {} \n ", .{ mx, my });

        // glfw.glfwGetWindowSize(window, &win_width, &win_height);
        // win_width = @floatToInt(i32, @intToFloat(f32, win_width) / scale);
        // win_height = @floatToInt(i32, @intToFloat(f32, win_height) / scale);
        // var fb_width: i32 = undefined;
        // var fb_height: i32 = undefined;
        // glfw.glfwGetFramebufferSize(window, &fb_width, &fb_height);

        // Update and render
        //c.glViewport(0, 0, fb_width, fb_height);
        // if (premult) {
        //     c.glClearColor(0, 0, 0, 0);
        // } else {
        //     c.glClearColor(0.3, 0.3, 0.32, 1.0);
        // }
        //c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
        //c.glClear(c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);

        // draw
        processing.begin_draw();
        try sketch.draw(&processing);
        processing.end_draw();

        // if (screenshot) {
        //     screenshot = false;
        //     const data = try Processing.saveScreenshot(allocator, fb_width, fb_height, premult);
        //     defer allocator.free(data);
        //     try std.fs.cwd().writeFile("dump.png", data);
        // }

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
        std.time.sleep(std.time.ns_per_ms * 16);
    }
}
