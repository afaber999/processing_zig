const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const c = @cImport({
    @cDefine("STBI_WRITE_NO_STDIO", "1");
    @cInclude("stb_image_write.h");
});
// const use_webgl = builtin.cpu.arch.isWasm();

// const gl = if (use_webgl)
//     @import("web/webgl.zig")
// else
//     @cImport({
//         @cInclude("glad/glad.h");
//     });
const gl = @cImport({
    @cInclude("glad/glad.h");
});

const nvg = @import("nanovg");

const Processing = @This();

fn isBlack(col: nvg.Color) bool {
    return col.r == 0 and col.g == 0 and col.b == 0 and col.a == 0;
}

pub fn load(processing: *Processing, vg: nvg) void {
    _ = processing;
    _ = vg;
}

pub fn free(processing: Processing, vg: nvg) void {
    _ = processing;
    _ = vg;
}

pub fn draw(demo: Processing, vg: nvg, mx: f32, my: f32, width: f32, height: f32, t: f32, blowup: bool) void {
    _ = demo;
    _ = blowup;

    drawEyes(vg, width - 250, 50, 150, 100, mx, my, t);
    drawLines(vg, 120, height - 50, 600, 50, t);
    drawWidths(vg, 10, 50, 30);
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

fn drawWidths(vg: nvg, x: f32, y0: f32, width: f32) void {
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
        vg.lineTo(x + width, y + width * 0.3);
        vg.stroke();
        y += 10;
    }
}
