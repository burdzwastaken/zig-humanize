//! Ordinal number formatting (1st, 2nd, 3rd, etc)

const std = @import("std");

const Writer = std.Io.Writer;

/// Comptime ordinal suffix
pub inline fn comptimeOrdinalSuffix(comptime x: i64) []const u8 {
    comptime {
        return getSuffix(@abs(x));
    }
}

/// Returns "st", "nd", "rd", or "th"
pub fn ordinalSuffix(x: i64) []const u8 {
    return getSuffix(@abs(x));
}

fn getSuffix(abs_x: u64) []const u8 {
    const last_two = abs_x % 100;
    if (last_two >= 11 and last_two <= 13) {
        return "th";
    }
    return switch (abs_x % 10) {
        1 => "st",
        2 => "nd",
        3 => "rd",
        else => "th",
    };
}

/// Ordinal number formatter
pub const Ordinal = struct {
    value: i64,

    pub fn init(value: i64) Ordinal {
        return .{ .value = value };
    }

    pub fn format(self: Ordinal, w: *Writer) Writer.Error!void {
        try w.print("{d}{s}", .{ self.value, ordinalSuffix(self.value) });
    }
};

pub fn ordinal(value: i64) Ordinal {
    return Ordinal.init(value);
}

/// `comptimeOrdinal(42)` -> `"42nd"`
pub inline fn comptimeOrdinal(comptime x: i64) []const u8 {
    comptime {
        const suffix = comptimeOrdinalSuffix(x);
        return std.fmt.comptimePrint("{d}{s}", .{ x, suffix });
    }
}

test "ordinal basic" {
    try std.testing.expectFmt("0th", "{f}", .{ordinal(0)});
    try std.testing.expectFmt("1st", "{f}", .{ordinal(1)});
    try std.testing.expectFmt("2nd", "{f}", .{ordinal(2)});
    try std.testing.expectFmt("3rd", "{f}", .{ordinal(3)});
    try std.testing.expectFmt("4th", "{f}", .{ordinal(4)});
}

test "ordinal teens" {
    try std.testing.expectFmt("11th", "{f}", .{ordinal(11)});
    try std.testing.expectFmt("12th", "{f}", .{ordinal(12)});
    try std.testing.expectFmt("13th", "{f}", .{ordinal(13)});
}

test "ordinal larger numbers" {
    try std.testing.expectFmt("21st", "{f}", .{ordinal(21)});
    try std.testing.expectFmt("22nd", "{f}", .{ordinal(22)});
    try std.testing.expectFmt("23rd", "{f}", .{ordinal(23)});
    try std.testing.expectFmt("100th", "{f}", .{ordinal(100)});
    try std.testing.expectFmt("101st", "{f}", .{ordinal(101)});
    try std.testing.expectFmt("111th", "{f}", .{ordinal(111)});
    try std.testing.expectFmt("112th", "{f}", .{ordinal(112)});
    try std.testing.expectFmt("113th", "{f}", .{ordinal(113)});
    try std.testing.expectFmt("193rd", "{f}", .{ordinal(193)});
}

test "ordinal negative" {
    try std.testing.expectFmt("-1st", "{f}", .{ordinal(-1)});
    try std.testing.expectFmt("-11th", "{f}", .{ordinal(-11)});
}

test "comptime ordinal" {
    try std.testing.expectEqualStrings("42nd", comptimeOrdinal(42));
    try std.testing.expectEqualStrings("1st", comptimeOrdinal(1));
    try std.testing.expectEqualStrings("11th", comptimeOrdinal(11));
}

test "ordinal with std.fmt" {
    var buf: [64]u8 = undefined;
    const result = try std.fmt.bufPrint(&buf, "You came in {f} place!", .{ordinal(1)});
    try std.testing.expectEqualStrings("You came in 1st place!", result);
}
