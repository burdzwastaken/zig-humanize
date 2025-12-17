//! Byte size formatting and parsing

const std = @import("std");
const ftoa = @import("ftoa.zig");

const Writer = std.Io.Writer;

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

const ByteCalc = struct {
    value: f64,
    unit_idx: usize,
};

fn calcBytes(n: u64, base: Bytes.Base) ByteCalc {
    const base_val: u64 = if (base == .si) 1000 else 1024;

    if (n < base_val) {
        return .{ .value = @floatFromInt(n), .unit_idx = 0 };
    }

    var val: f64 = @floatFromInt(n);
    var i: usize = 0;

    while (val >= @as(f64, @floatFromInt(base_val)) and i < si_sizes.len - 1) {
        val /= @floatFromInt(base_val);
        i += 1;
    }

    return .{ .value = val, .unit_idx = i };
}

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

    pub fn format(self: Bytes, w: *Writer) Writer.Error!void {
        const sizes = if (self.base == .si) &si_sizes else &iec_sizes;
        const calc = calcBytes(self.value, self.base);
        const precision = self.precision orelse 3;

        if (calc.unit_idx == 0 and calc.value == @floor(calc.value)) {
            try w.print("{d} B", .{@as(u64, @intFromFloat(calc.value))});
        } else {
            try ftoa.formatFloatWithPrecision(w, calc.value, precision);
            try w.print(" {s}", .{sizes[calc.unit_idx]});
        }
    }
};

pub fn si(value: u64) Bytes {
    return Bytes.si(value);
}

pub fn iec(value: u64) Bytes {
    return Bytes.iec(value);
}

pub const ParseBytesError = error{
    InvalidFormat,
    Overflow,
};

/// `parseBytes("42 MB")` -> `42000000`
pub fn parseBytes(s: []const u8) ParseBytesError!u64 {
    const parsed = ftoa.parseNumericPrefix(s, false) orelse return error.InvalidFormat;

    const value = std.fmt.parseFloat(f64, parsed.num) catch return error.InvalidFormat;
    const multiplier = getMultiplier(parsed.rest) orelse return error.InvalidFormat;

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
    return std.ascii.toLower(c);
}

fn eqlLower(a: []const u8, b: []const u8) bool {
    return std.ascii.eqlIgnoreCase(a, b);
}

/// `comptimeBytes(4096)` -> `"4.096 kB"`
pub inline fn comptimeBytes(comptime n: u64) []const u8 {
    comptime {
        return comptimeBytesImpl(n, .si, 3);
    }
}

/// `comptimeIBytes(4096)` -> `"4 KiB"`
pub inline fn comptimeIBytes(comptime n: u64) []const u8 {
    comptime {
        return comptimeBytesImpl(n, .iec, 3);
    }
}

pub inline fn comptimeBytesWithPrecision(comptime n: u64, comptime precision: u8) []const u8 {
    comptime {
        return comptimeBytesImpl(n, .si, precision);
    }
}

pub inline fn comptimeIBytesWithPrecision(comptime n: u64, comptime precision: u8) []const u8 {
    comptime {
        return comptimeBytesImpl(n, .iec, precision);
    }
}

inline fn comptimeBytesImpl(comptime n: u64, comptime base: Bytes.Base, comptime precision: u8) []const u8 {
    comptime {
        const sizes = if (base == .si) si_sizes else iec_sizes;
        const calc = calcBytes(n, base);

        if (calc.unit_idx == 0 and calc.value == @floor(calc.value)) {
            return std.fmt.comptimePrint("{d} B", .{@as(u64, @intFromFloat(calc.value))});
        }

        return std.fmt.comptimePrint("{s} {s}", .{ ftoa.comptimeFormatFloat(calc.value, precision), sizes[calc.unit_idx] });
    }
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

test "comptimeBytes" {
    try std.testing.expectEqualStrings("0 B", comptimeBytes(0));
    try std.testing.expectEqualStrings("999 B", comptimeBytes(999));
    try std.testing.expectEqualStrings("1 kB", comptimeBytes(1000));
    try std.testing.expectEqualStrings("82.855 MB", comptimeBytes(82854982));
    try std.testing.expectEqualStrings("1 GB", comptimeBytes(1000000000));
}

test "comptimeIBytes" {
    try std.testing.expectEqualStrings("0 B", comptimeIBytes(0));
    try std.testing.expectEqualStrings("1023 B", comptimeIBytes(1023));
    try std.testing.expectEqualStrings("1 KiB", comptimeIBytes(1024));
    try std.testing.expectEqualStrings("4 KiB", comptimeIBytes(4096));
    try std.testing.expectEqualStrings("79.017 MiB", comptimeIBytes(82854982));
}

test "comptimeBytes with precision" {
    try std.testing.expectEqualStrings("82.85 MB", comptimeBytesWithPrecision(82854982, 2));
    try std.testing.expectEqualStrings("79.02 MiB", comptimeIBytesWithPrecision(82854982, 2));
}
