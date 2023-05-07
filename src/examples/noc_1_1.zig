// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com
// Example 1-1: Bouncing Ball, no vectors

const std = @import("std");
const print = std.debug.print;
const Self = @This();

const Processing = @import("../processing.zig");

var x: f32 = 100;
var y: f32 = 100;
var xspeed: f32 = 2.5;
var yspeed: f32 = 2.0;

pub fn setup(self: *Self, p: *Processing) anyerror!void {
    _ = p;
    //p.size(800, 200);
    // p.smooth();
    _ = self;
}

pub fn draw(self: *Self, p: *Processing) anyerror!void {
    _ = self;

    // Add the current speed to the position.
    x = x + xspeed;
    y = y + yspeed;

    // convert image widht/height to float
    const fw = @intToFloat(f32, p.width());
    const fh = @intToFloat(f32, p.height());

    if ((x >= fw) or (x < 0)) {
        xspeed = xspeed * -1;
    }
    if ((y >= fh) or (y < 0)) {
        yspeed = yspeed * -1;
    }

    // Display circle at x,y position
    p.background_grey(255);
    p.stroke(0, 0, 0);
    p.stroke_weight(2);
    p.fill(255, 127, 127);
    p.ellipse(x, y, 48, 48);
}
