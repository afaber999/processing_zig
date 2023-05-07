// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com
// Example 1-2: Bouncing Ball, vectors

const Self = @This();
const Processing = @import("../processing.zig");
const Vector2 = Processing.Vector2;

position: Vector2,
velocity: Vector2,

pub fn setup(self: *Self, p: *Processing) anyerror!void {
    _ = p;
    self.position = Vector2.create(100, 100);
    self.velocity = Vector2.create(2.5, 2.0);
}

pub fn draw(self: *Self, p: *Processing) anyerror!void {

    // Add the current speed to the position.
    self.position = self.position.add(self.velocity);
    // or self.position = Vector2.add(self.position, self.velocity);

    // convert image widht/height to float
    const fw = @intToFloat(f32, p.width());
    const fh = @intToFloat(f32, p.height());

    if ((self.position.x >= fw) or (self.position.x < 0)) {
        self.velocity.x *= -1;
    }
    if ((self.position.y >= fh) or (self.position.y < 0)) {
        self.velocity.y *= -1;
    }

    // Display circle at position
    p.background_grey(255);
    p.stroke(0, 0, 0);
    p.stroke_weight(2);
    p.fill(255, 127, 127);
    p.ellipse(self.position.x, self.position.y, 16, 16);
}
