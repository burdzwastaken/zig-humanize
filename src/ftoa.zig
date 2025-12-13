//! Float formatting without trailing zeros

const std = @import("std");

pub const max_buf_size = 32;

pub fn formatFloat(w: *std.io.Writer, num: f64) std.io.Writer.Error!void {
    if (std.math.isNan(num)) {
        try w.writeAll("NaN");
        return;
    }
    if (std.math.isPositiveInf(num)) {
        try w.writeAll("+Inf");
        return;
    }
    if (std.math.isNegativeInf(num)) {
        try w.writeAll("-Inf");
        return;
    }

    var buf: [max_buf_size]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buf, "{d:.6}", .{num}) catch return error.WriteFailed;
    const stripped = stripTrailingZeros(formatted);
    try w.writeAll(stripped);
}

pub fn formatFloatWithPrecision(w: *std.io.Writer, num: f64, precision: u8) std.io.Writer.Error!void {
    if (std.math.isNan(num)) {
        try w.writeAll("NaN");
        return;
    }
    if (std.math.isPositiveInf(num)) {
        try w.writeAll("+Inf");
        return;
    }
    if (std.math.isNegativeInf(num)) {
        try w.writeAll("-Inf");
        return;
    }

    var buf: [max_buf_size]u8 = undefined;
    const formatted = formatWithPrecision(&buf, num, precision);

    const stripped = stripTrailingZeros(formatted);
    try w.writeAll(stripped);
}

fn formatWithPrecision(buf: []u8, num: f64, precision: u8) []const u8 {
    return switch (precision) {
        0 => std.fmt.bufPrint(buf, "{d:.0}", .{num}) catch "?",
        1 => std.fmt.bufPrint(buf, "{d:.1}", .{num}) catch "?",
        2 => std.fmt.bufPrint(buf, "{d:.2}", .{num}) catch "?",
        3 => std.fmt.bufPrint(buf, "{d:.3}", .{num}) catch "?",
        4 => std.fmt.bufPrint(buf, "{d:.4}", .{num}) catch "?",
        5 => std.fmt.bufPrint(buf, "{d:.5}", .{num}) catch "?",
        6 => std.fmt.bufPrint(buf, "{d:.6}", .{num}) catch "?",
        7 => std.fmt.bufPrint(buf, "{d:.7}", .{num}) catch "?",
        8 => std.fmt.bufPrint(buf, "{d:.8}", .{num}) catch "?",
        else => std.fmt.bufPrint(buf, "{d:.9}", .{num}) catch "?",
    };
}

fn stripTrailingZeros(s: []const u8) []const u8 {
    const dot_pos = std.mem.indexOf(u8, s, ".") orelse return s;

    var end = s.len;
    while (end > dot_pos + 1 and s[end - 1] == '0') {
        end -= 1;
    }

    if (end == dot_pos + 1) {
        end = dot_pos;
    }

    return s[0..end];
}

/// Float formatter
pub const Float = struct {
    value: f64,
    precision: ?u8 = null,

    pub fn init(value: f64) Float {
        return .{ .value = value };
    }

    pub fn withPrecision(self: Float, p: u8) Float {
        return .{ .value = self.value, .precision = p };
    }

    pub fn format(self: Float, w: *std.io.Writer) std.io.Writer.Error!void {
        if (self.precision) |p| {
            try formatFloatWithPrecision(w, self.value, p);
        } else {
            try formatFloat(w, self.value);
        }
    }
};

pub fn floatToString(value: f64) Float {
    return Float.init(value);
}

pub fn floatToStringWithPrecision(value: f64, precision: u8) Float {
    return Float.init(value).withPrecision(precision);
}

test "formatFloat basic" {
    try std.testing.expectFmt("2.24", "{f}", .{Float.init(2.24)});
    try std.testing.expectFmt("2", "{f}", .{Float.init(2.0)});
    try std.testing.expectFmt("0", "{f}", .{Float.init(0.0)});
    try std.testing.expectFmt("-1.5", "{f}", .{Float.init(-1.5)});
    try std.testing.expectFmt("100", "{f}", .{Float.init(100.0)});
}

test "formatFloat with precision" {
    try std.testing.expectFmt("2.2", "{f}", .{Float.init(2.24).withPrecision(1)});
    try std.testing.expectFmt("2", "{f}", .{Float.init(2.0).withPrecision(2)});
    try std.testing.expectFmt("3.14", "{f}", .{Float.init(3.14159).withPrecision(2)});
    try std.testing.expectFmt("3", "{f}", .{Float.init(3.14159).withPrecision(0)});
}

test "formatFloat special values" {
    try std.testing.expectFmt("NaN", "{f}", .{Float.init(std.math.nan(f64))});
    try std.testing.expectFmt("+Inf", "{f}", .{Float.init(std.math.inf(f64))});
    try std.testing.expectFmt("-Inf", "{f}", .{Float.init(-std.math.inf(f64))});
}
