const std = @import("std");

const Self = @This();

x: f32,
y: f32,

pub fn create(x_val: f32, y_val: f32) Self {
    return Self{
        .x = x_val,
        .y = y_val,
    };
}

pub fn add(a: Self, b: Self) Self {
    return Self{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn sub(a: Self, b: Self) Self {
    return Self{
        .x = a.x - b.x,
        .y = a.y - b.y,
    };
}

pub fn length(a: Self) f32 {
    return std.math.sqrt(a.x * a.x + a.y * a.y);
}

pub fn normaize(a: Self) Self {
    const l = length(a);
    return Self{
        .x = a.x / l,
        .y = a.y / l,
    };
}
