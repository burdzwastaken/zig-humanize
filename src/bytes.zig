//! Byte size formatting and parsing

const std = @import("std");
const ftoa = @import("ftoa.zig");

/// IEC sizes (binary, base 1024)
pub const Byte: u64 = 1;
pub const KiByte: u64 = 1024;
pub const MiByte: u64 = 1024 * KiByte;
pub const GiByte: u64 = 1024 * MiByte;
pub const TiByte: u64 = 1024 * GiByte;
pub const PiByte: u64 = 1024 * TiByte;
pub const EiByte: u64 = 1024 * PiByte;

/// SI sizes (decimal, base 1000)
pub const KByte: u64 = 1000;
pub const MByte: u64 = 1000 * KByte;
pub const GByte: u64 = 1000 * MByte;
pub const TByte: u64 = 1000 * GByte;
pub const PByte: u64 = 1000 * TByte;
pub const EByte: u64 = 1000 * PByte;

const iec_sizes = [_][]const u8{ "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB" };
const si_sizes = [_][]const u8{ "B", "kB", "MB", "GB", "TB", "PB", "EB" };

/// Byte size formatter
pub const Bytes = struct {
    value: u64,
    base: Base = .si,
    precision: ?u8 = null,

    pub const Base = enum { si, iec };

    /// `Bytes.si(82854982)` -> `"82.855 MB"`
    pub fn si(value: u64) Bytes {
        return .{ .value = value, .base = .si };
    }

    /// `Bytes.iec(82854982)` -> `"79.017 MiB"`
    pub fn iec(value: u64) Bytes {
        return .{ .value = value, .base = .iec };
    }

    pub fn withPrecision(self: Bytes, p: u8) Bytes {
        return .{ .value = self.value, .base = self.base, .precision = p };
    }

    pub fn format(self: Bytes, w: *std.io.Writer) std.io.Writer.Error!void {
        const base_val: u64 = if (self.base == .si) 1000 else 1024;
        const sizes = if (self.base == .si) &si_sizes else &iec_sizes;

        if (self.value < base_val) {
            try w.print("{d} B", .{self.value});
            return;
        }

        var val: f64 = @floatFromInt(self.value);
        var i: usize = 0;

        while (val >= @as(f64, @floatFromInt(base_val)) and i < sizes.len - 1) {
            val /= @floatFromInt(base_val);
            i += 1;
        }

        const precision = self.precision orelse 3;
        try ftoa.formatFloatWithPrecision(w, val, precision);
        try w.print(" {s}", .{sizes[i]});
    }
};

pub fn IBytes(value: u64) Bytes {
    return Bytes.iec(value);
}

pub const ParseBytesError = error{
    InvalidFormat,
    Overflow,
};

/// `parseBytes("42 MB")` -> `42000000`
pub fn parseBytes(s: []const u8) ParseBytesError!u64 {
    const trimmed = std.mem.trim(u8, s, " \t\n\r");
    if (trimmed.len == 0) return error.InvalidFormat;

    var num_end: usize = 0;
    var has_decimal = false;

    for (trimmed, 0..) |c, i| {
        if (c == '.') {
            if (has_decimal) break;
            has_decimal = true;
            num_end = i + 1;
        } else if (c >= '0' and c <= '9') {
            num_end = i + 1;
        } else if (c == '-' and i == 0) {
            num_end = 1;
        } else {
            break;
        }
    }

    if (num_end == 0) return error.InvalidFormat;

    const num_str = trimmed[0..num_end];
    const unit_str = std.mem.trim(u8, trimmed[num_end..], " \t");

    const value = std.fmt.parseFloat(f64, num_str) catch return error.InvalidFormat;
    const multiplier = getMultiplier(unit_str) orelse return error.InvalidFormat;

    const result = value * @as(f64, @floatFromInt(multiplier));
    if (result < 0 or result > @as(f64, @floatFromInt(std.math.maxInt(u64)))) {
        return error.Overflow;
    }

    return @intFromFloat(result);
}

fn getMultiplier(unit: []const u8) ?u64 {
    if (unit.len == 0 or eqlLower(unit, "b") or eqlLower(unit, "byte") or eqlLower(unit, "bytes")) {
        return 1;
    }

    if (unit.len >= 3 and eqlLower(unit[unit.len - 2 ..], "ib")) {
        return switch (toLower(unit[0])) {
            'k' => KiByte,
            'm' => MiByte,
            'g' => GiByte,
            't' => TiByte,
            'p' => PiByte,
            'e' => EiByte,
            else => null,
        };
    }

    const prefix = toLower(unit[0]);
    return switch (prefix) {
        'k' => KByte,
        'm' => MByte,
        'g' => GByte,
        't' => TByte,
        'p' => PByte,
        'e' => EByte,
        else => null,
    };
}

fn toLower(c: u8) u8 {
    return if (c >= 'A' and c <= 'Z') c + 32 else c;
}

fn eqlLower(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ac, bc| {
        if (toLower(ac) != toLower(bc)) return false;
    }
    return true;
}

test "Bytes SI formatting" {
    try std.testing.expectFmt("0 B", "{f}", .{Bytes.si(0)});
    try std.testing.expectFmt("999 B", "{f}", .{Bytes.si(999)});
    try std.testing.expectFmt("1 kB", "{f}", .{Bytes.si(1000)});
    try std.testing.expectFmt("82.855 MB", "{f}", .{Bytes.si(82854982)});
    try std.testing.expectFmt("1 GB", "{f}", .{Bytes.si(1000000000)});
}

test "Bytes IEC formatting" {
    try std.testing.expectFmt("0 B", "{f}", .{Bytes.iec(0)});
    try std.testing.expectFmt("1023 B", "{f}", .{Bytes.iec(1023)});
    try std.testing.expectFmt("1 KiB", "{f}", .{Bytes.iec(1024)});
    try std.testing.expectFmt("79.017 MiB", "{f}", .{Bytes.iec(82854982)});
}

test "Bytes with precision" {
    try std.testing.expectFmt("82.85 MB", "{f}", .{Bytes.si(82854982).withPrecision(2)});
    try std.testing.expectFmt("79.02 MiB", "{f}", .{Bytes.iec(82854982).withPrecision(2)});
}

test "parseBytes" {
    try std.testing.expectEqual(@as(u64, 42), try parseBytes("42"));
    try std.testing.expectEqual(@as(u64, 42), try parseBytes("42 B"));
    try std.testing.expectEqual(@as(u64, 42000), try parseBytes("42 kB"));
    try std.testing.expectEqual(@as(u64, 42000), try parseBytes("42kB"));
    try std.testing.expectEqual(@as(u64, 42000000), try parseBytes("42 MB"));
    try std.testing.expectEqual(@as(u64, 42000000000), try parseBytes("42 GB"));
    try std.testing.expectEqual(@as(u64, 43008), try parseBytes("42 KiB"));
    try std.testing.expectEqual(@as(u64, 44040192), try parseBytes("42 MiB"));
    try std.testing.expectEqual(@as(u64, 45097156608), try parseBytes("42 GiB"));
    try std.testing.expectEqual(@as(u64, 1500), try parseBytes("1.5 kB"));
}
