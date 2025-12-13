//! Float formatting without trailing zeros

const std = @import("std");

pub const Writer = std.Io.Writer;

pub const max_buf_size = std.fmt.float.min_buffer_size;

pub const SpecialFloat = enum { nan, positive_inf, negative_inf, normal };

pub fn classifyFloat(num: f64) SpecialFloat {
    if (std.math.isNan(num)) return .nan;
    if (std.math.isPositiveInf(num)) return .positive_inf;
    if (std.math.isNegativeInf(num)) return .negative_inf;
    return .normal;
}

pub fn writeSpecialFloat(w: *Writer, class: SpecialFloat) Writer.Error!bool {
    switch (class) {
        .nan => try w.writeAll("NaN"),
        .positive_inf => try w.writeAll("+Inf"),
        .negative_inf => try w.writeAll("-Inf"),
        .normal => return false,
    }
    return true;
}

pub fn formatFloat(w: *Writer, num: f64) Writer.Error!void {
    try formatFloatWithPrecision(w, num, 6);
}

pub fn formatFloatWithPrecision(w: *Writer, num: f64, precision: u8) Writer.Error!void {
    if (try writeSpecialFloat(w, classifyFloat(num))) return;

    var buf: [max_buf_size]u8 = undefined;
    const formatted = std.fmt.float.render(&buf, num, .{
        .mode = .decimal,
        .precision = precision,
    }) catch return error.WriteFailed;
    try w.writeAll(stripTrailingZeros(formatted));
}

pub fn bufPrintFloat(buf: []u8, num: f64, precision: u8) []const u8 {
    return std.fmt.float.render(buf, num, .{
        .mode = .decimal,
        .precision = precision,
    }) catch "?";
}

pub fn stripTrailingZeros(s: []const u8) []const u8 {
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

pub inline fn comptimeStripTrailingZeros(comptime s: []const u8) []const u8 {
    comptime {
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
}

pub inline fn comptimeFormatFloat(comptime val: f64, comptime precision: u8) []const u8 {
    comptime {
        const raw = switch (precision) {
            0 => std.fmt.comptimePrint("{d:.0}", .{val}),
            1 => std.fmt.comptimePrint("{d:.1}", .{val}),
            2 => std.fmt.comptimePrint("{d:.2}", .{val}),
            3 => std.fmt.comptimePrint("{d:.3}", .{val}),
            4 => std.fmt.comptimePrint("{d:.4}", .{val}),
            5 => std.fmt.comptimePrint("{d:.5}", .{val}),
            6 => std.fmt.comptimePrint("{d:.6}", .{val}),
            else => std.fmt.comptimePrint("{d:.6}", .{val}),
        };
        return comptimeStripTrailingZeros(raw);
    }
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

    pub fn format(self: Float, w: *Writer) Writer.Error!void {
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
