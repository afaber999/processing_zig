// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com
// Example 1-2: Bouncing Ball, vectors
// ZIG port by Albert Faber

const Self = @This();
const Processing = @import("../processing.zig");
const Vector2 = Processing.Vector2;

position: Vector2,
velocity: Vector2,

pub fn setup(self: *Self, p: *Processing) anyerror!void {
    p.size(200, 200);
    p.background(255, 255, 255, 255);
    self.position = Vector2.create(100, 100);
    self.velocity = Vector2.create(2.5, 2.0);
}

pub fn draw(self: *Self, p: *Processing) anyerror!void {
    p.no_stroke();
    p.fill(255, 255, 255, 10);
    p.rect(0, 0, @intToFloat(f32, p.width()), @intToFloat(f32, p.height()));

    // Add the current speed to the position.
    self.position = self.position.add(self.velocity);

    // check borders
    if ((self.position.x >= @intToFloat(f32, p.width())) or (self.position.x < 0)) {
        self.velocity.x *= -1;
    }
    if ((self.position.y >= @intToFloat(f32, p.height())) or (self.position.y < 0)) {
        self.velocity.y *= -1;
    }

    // Display circle at position
    p.stroke(0, 0, 0, 255);
    p.stroke_weight(5);
    p.fill(175, 175, 175, 255);
    p.ellipse(self.position.x, self.position.y, 16, 16);
}
