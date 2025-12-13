//! SI (metric) prefix formatting and parsing

const std = @import("std");
const ftoa = @import("ftoa.zig");

const Writer = std.Io.Writer;

const Prefix = struct {
    exponent: i8,
    symbol: []const u8,
    name: []const u8,
};

const prefixes = [_]Prefix{
    .{ .exponent = -30, .symbol = "q", .name = "quecto" },
    .{ .exponent = -27, .symbol = "r", .name = "ronto" },
    .{ .exponent = -24, .symbol = "y", .name = "yocto" },
    .{ .exponent = -21, .symbol = "z", .name = "zepto" },
    .{ .exponent = -18, .symbol = "a", .name = "atto" },
    .{ .exponent = -15, .symbol = "f", .name = "femto" },
    .{ .exponent = -12, .symbol = "p", .name = "pico" },
    .{ .exponent = -9, .symbol = "n", .name = "nano" },
    .{ .exponent = -6, .symbol = "µ", .name = "micro" },
    .{ .exponent = -3, .symbol = "m", .name = "milli" },
    .{ .exponent = 0, .symbol = "", .name = "" },
    .{ .exponent = 3, .symbol = "k", .name = "kilo" },
    .{ .exponent = 6, .symbol = "M", .name = "mega" },
    .{ .exponent = 9, .symbol = "G", .name = "giga" },
    .{ .exponent = 12, .symbol = "T", .name = "tera" },
    .{ .exponent = 15, .symbol = "P", .name = "peta" },
    .{ .exponent = 18, .symbol = "E", .name = "exa" },
    .{ .exponent = 21, .symbol = "Z", .name = "zetta" },
    .{ .exponent = 24, .symbol = "Y", .name = "yotta" },
    .{ .exponent = 27, .symbol = "R", .name = "ronna" },
    .{ .exponent = 30, .symbol = "Q", .name = "quetta" },
};

const zero_idx: usize = 10;

pub const SIResult = struct {
    value: f64,
    prefix: []const u8,
    exponent: i8,
};

pub fn computeSI(input: f64) SIResult {
    if (input == 0 or std.math.isNan(input) or std.math.isInf(input)) {
        return .{ .value = input, .prefix = "", .exponent = 0 };
    }

    const abs_input = @abs(input);
    const sign: f64 = if (input < 0) -1.0 else 1.0;

    const log_val = @log10(abs_input);
    const target_exp: i8 = @intFromFloat(@floor(log_val));

    var best_idx: usize = zero_idx;
    for (prefixes, 0..) |prefix, i| {
        if (prefix.exponent <= target_exp) {
            best_idx = i;
        } else {
            break;
        }
    }

    const exp: f64 = @floatFromInt(prefixes[best_idx].exponent);
    const adjusted = abs_input / std.math.pow(f64, 10.0, exp);

    return .{
        .value = sign * adjusted,
        .prefix = prefixes[best_idx].symbol,
        .exponent = prefixes[best_idx].exponent,
    };
}

/// SI notation formatter
pub const SI = struct {
    value: f64,
    unit: []const u8,
    precision: ?u8 = null,

    pub fn init(value: f64, unit: []const u8) SI {
        return .{ .value = value, .unit = unit };
    }

    pub fn withPrecision(self: SI, p: u8) SI {
        return .{ .value = self.value, .unit = self.unit, .precision = p };
    }

    pub fn format(self: SI, w: *Writer) Writer.Error!void {
        const result = computeSI(self.value);

        if (self.precision) |p| {
            try ftoa.formatFloatWithPrecision(w, result.value, p);
        } else {
            try ftoa.formatFloat(w, result.value);
        }
        try w.print(" {s}{s}", .{ result.prefix, self.unit });
    }
};

pub fn si(value: f64, unit: []const u8) SI {
    return SI.init(value, unit);
}

pub const ParseSIError = error{
    InvalidFormat,
};

pub const ParseResult = struct {
    value: f64,
    unit: []const u8,
};

/// `parseSI("2.5 kB")` -> `{ .value = 2500, .unit = "B" }`
pub fn parseSI(input: []const u8) ParseSIError!ParseResult {
    const trimmed = std.mem.trim(u8, input, " \t\n\r");
    if (trimmed.len == 0) return error.InvalidFormat;

    var num_end: usize = 0;
    var has_decimal = false;
    var has_exp = false;

    for (trimmed, 0..) |c, i| {
        if (c == '.') {
            if (has_decimal) break;
            has_decimal = true;
            num_end = i + 1;
        } else if (c == 'e' or c == 'E') {
            if (has_exp) break;
            has_exp = true;
            num_end = i + 1;
        } else if (c >= '0' and c <= '9') {
            num_end = i + 1;
        } else if ((c == '-' or c == '+') and (i == 0 or (has_exp and i == num_end))) {
            num_end = i + 1;
        } else {
            break;
        }
    }

    if (num_end == 0) return error.InvalidFormat;

    const num_str = trimmed[0..num_end];
    const rest = std.mem.trim(u8, trimmed[num_end..], " \t");

    const base_value = std.fmt.parseFloat(f64, num_str) catch return error.InvalidFormat;

    if (rest.len == 0) {
        return .{ .value = base_value, .unit = "" };
    }

    for (prefixes) |prefix| {
        if (prefix.symbol.len > 0 and rest.len >= prefix.symbol.len) {
            if (std.mem.startsWith(u8, rest, prefix.symbol)) {
                const unit = rest[prefix.symbol.len..];
                const exp: f64 = @floatFromInt(prefix.exponent);
                const multiplier = std.math.pow(f64, 10.0, exp);
                return .{
                    .value = base_value * multiplier,
                    .unit = unit,
                };
            }
        }
    }

    return .{ .value = base_value, .unit = rest };
}

test "computeSI" {
    {
        const result = computeSI(1000.0);
        try std.testing.expectApproxEqAbs(@as(f64, 1.0), result.value, 0.001);
        try std.testing.expectEqualStrings("k", result.prefix);
    }
    {
        const result = computeSI(1000000.0);
        try std.testing.expectApproxEqAbs(@as(f64, 1.0), result.value, 0.001);
        try std.testing.expectEqualStrings("M", result.prefix);
    }
    {
        const result = computeSI(2.2345e-12);
        try std.testing.expectApproxEqAbs(@as(f64, 2.2345), result.value, 0.0001);
        try std.testing.expectEqualStrings("p", result.prefix);
    }
    {
        const result = computeSI(0.0);
        try std.testing.expectEqual(@as(f64, 0.0), result.value);
        try std.testing.expectEqualStrings("", result.prefix);
    }
}

test "SI formatting" {
    try std.testing.expectFmt("1 MB", "{f}", .{si(1000000, "B")});
    try std.testing.expectFmt("2.2345 pF", "{f}", .{si(2.2345e-12, "F")});
    try std.testing.expectFmt("2.23 nM", "{f}", .{si(0.00000000223, "M")});
}

test "SI with precision" {
    try std.testing.expectFmt("2.23 pF", "{f}", .{si(2.2345e-12, "F").withPrecision(2)});
    try std.testing.expectFmt("1 MB", "{f}", .{si(1000000, "B").withPrecision(0)});
}

/// `comptimeSI(1000000, "B")` -> `"1 MB"`
pub inline fn comptimeSI(comptime value: f64, comptime unit: []const u8) []const u8 {
    comptime {
        return comptimeSIImpl(value, unit, 4);
    }
}

pub inline fn comptimeSIWithPrecision(comptime value: f64, comptime unit: []const u8, comptime precision: u8) []const u8 {
    comptime {
        return comptimeSIImpl(value, unit, precision);
    }
}

inline fn comptimeSIImpl(comptime value: f64, comptime unit: []const u8, comptime precision: u8) []const u8 {
    comptime {
        const result = computeSIComptime(value);
        return std.fmt.comptimePrint("{s} {s}{s}", .{ ftoa.comptimeFormatFloat(result.value, precision), result.prefix, unit });
    }
}

inline fn computeSIComptime(comptime input: f64) SIResult {
    comptime {
        if (input == 0 or std.math.isNan(input) or std.math.isInf(input)) {
            return .{ .value = input, .prefix = "", .exponent = 0 };
        }

        const abs_input = @abs(input);
        const sign: f64 = if (input < 0) -1.0 else 1.0;

        const log_val = @log10(abs_input);
        const target_exp: i8 = @intFromFloat(@floor(log_val));

        var best_idx: usize = zero_idx;
        for (prefixes, 0..) |prefix, i| {
            if (prefix.exponent <= target_exp) {
                best_idx = i;
            } else {
                break;
            }
        }

        const exp: f64 = @floatFromInt(prefixes[best_idx].exponent);
        const adjusted = abs_input / std.math.pow(f64, 10.0, exp);

        return .{
            .value = sign * adjusted,
            .prefix = prefixes[best_idx].symbol,
            .exponent = prefixes[best_idx].exponent,
        };
    }
}

test "parseSI" {
    {
        const result = try parseSI("2.2345 pF");
        try std.testing.expectApproxEqAbs(@as(f64, 2.2345e-12), result.value, 1e-20);
        try std.testing.expectEqualStrings("F", result.unit);
    }
    {
        const result = try parseSI("1 MB");
        try std.testing.expectApproxEqAbs(@as(f64, 1000000.0), result.value, 0.1);
        try std.testing.expectEqualStrings("B", result.unit);
    }
    {
        const result = try parseSI("42");
        try std.testing.expectApproxEqAbs(@as(f64, 42.0), result.value, 0.001);
        try std.testing.expectEqualStrings("", result.unit);
    }
}

test "comptimeSI" {
    try std.testing.expectEqualStrings("1 MB", comptimeSI(1000000, "B"));
    try std.testing.expectEqualStrings("2.2345 pF", comptimeSI(2.2345e-12, "F"));
    try std.testing.expectEqualStrings("2.23 nM", comptimeSI(0.00000000223, "M"));
}

test "comptimeSI with precision" {
    try std.testing.expectEqualStrings("2.23 pF", comptimeSIWithPrecision(2.2345e-12, "F", 2));
    try std.testing.expectEqualStrings("1 MB", comptimeSIWithPrecision(1000000, "B", 0));
}
