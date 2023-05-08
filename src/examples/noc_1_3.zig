// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com
// Example 1-3: Vector subtraction
// ZIG port by Albert Faber

const Self = @This();
const Processing = @import("../processing.zig");
const Vector2 = Processing.Vector2;

pub fn setup(self: *Self, p: *Processing) anyerror!void {
    _ = self;
    p.size(640, 360);
}

pub fn draw(self: *Self, p: *Processing) anyerror!void {
    _ = self;
    p.background(255, 255, 255, 255);

    var mouse = Vector2.create(@intToFloat(f32, p.mouse_x()), @intToFloat(f32, p.mouse_y()));
    var center = Vector2.create(@intToFloat(f32, p.width()) / 2, @intToFloat(f32, p.height()) / 2);
    mouse = mouse.sub(center);

    p.translate(center.x, center.y);
    p.stroke_weight(2);
    p.stroke(0, 0, 0, 255);
    p.line(0, 0, mouse.x, mouse.y);
}
