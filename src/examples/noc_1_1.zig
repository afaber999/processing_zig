// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com
// Example 1-1: Bouncing Ball, no vectors
// ZIG port by Albert Faber

const std = @import("std");
const print = std.debug.print;
const Self = @This();

const Processing = @import("../processing.zig");

var x: f32 = 100;
var y: f32 = 100;
var xspeed: f32 = 2.5;
var yspeed: f32 = 2.0;

pub fn setup(self: *Self, p: *Processing) anyerror!void {
    p.size(800, 200);
    // p.smooth();
    _ = self;
}

pub fn draw(self: *Self, p: *Processing) anyerror!void {
    _ = self;
    p.background_grey(255);

    // Add the current speed to the position.
    x = x + xspeed;
    y = y + yspeed;

    // check borders
    if ((x >= @intToFloat(f32, p.width())) or (x < 0)) {
        xspeed = xspeed * -1;
    }
    if ((y >= @intToFloat(f32, p.height())) or (y < 0)) {
        yspeed = yspeed * -1;
    }

    // Display circle at x,y position
    p.stroke(0, 0, 0, 255);
    p.stroke_weight(2);
    p.fill(127, 127, 127, 255);
    p.ellipse(x, y, 48, 48);
}
