//! Custom number formatting

const std = @import("std");

/// Format a float with custom separators.
///
/// Format string examples:
/// - `"#,###.##"` => `"12,345.67"` (US format)
/// - `"#.###,##"` => `"12.345,67"` (European format)
/// - `"# ###,##"` => `"12 345,67"` (space as thousand separator)
///
/// The `#` characters are placeholders:
/// - Characters before the last special char (`.` or `,`) are the integer part
/// - The character used as separator in the integer part becomes the thousand separator
/// - The character used to separate integer from decimal becomes the decimal separator
pub fn formatFloat(allocator: std.mem.Allocator, format: []const u8, n: f64) ![]u8 {
    // special cases
    if (std.math.isNan(n)) {
        return allocator.dupe(u8, "NaN");
    }
    if (std.math.isPositiveInf(n)) {
        return allocator.dupe(u8, "+Inf");
    }
    if (std.math.isNegativeInf(n)) {
        return allocator.dupe(u8, "-Inf");
    }

    const config = parseFormat(format);

    return formatWithConfig(allocator, n, config);
}

/// Format an integer with custom separators
pub fn formatInteger(allocator: std.mem.Allocator, format: []const u8, n: i64) ![]u8 {
    return formatFloat(allocator, format, @floatFromInt(n));
}

const FormatConfig = struct {
    thousand_sep: u8,
    decimal_sep: u8,
    precision: ?usize,
};

fn parseFormat(format: []const u8) FormatConfig {
    if (format.len == 0) {
        return .{
            .thousand_sep = ',',
            .decimal_sep = '.',
            .precision = 2,
        };
    }

    var thousand_sep: u8 = ',';
    var decimal_sep: u8 = '.';
    var precision: ?usize = null;

    var last_sep_pos: ?usize = null;
    var last_sep_char: u8 = 0;

    for (format, 0..) |c, i| {
        if (c == '.' or c == ',' or c == ' ') {
            last_sep_pos = i;
            last_sep_char = c;
        }
    }

    if (last_sep_pos) |pos| {
        decimal_sep = last_sep_char;

        var prec: usize = 0;
        for (format[pos + 1 ..]) |c| {
            if (c == '#') {
                prec += 1;
            }
        }
        precision = prec;

        for (format[0..pos]) |c| {
            if (c == '.' or c == ',' or c == ' ') {
                thousand_sep = c;
                break;
            }
        }

        if (decimal_sep == thousand_sep) {
            if (decimal_sep == '.') {
                thousand_sep = ',';
            } else {
                thousand_sep = '.';
            }
        }
    }

    return .{
        .thousand_sep = thousand_sep,
        .decimal_sep = decimal_sep,
        .precision = precision,
    };
}

fn formatWithConfig(allocator: std.mem.Allocator, n: f64, config: FormatConfig) ![]u8 {
    const negative = n < 0;
    const abs_n = @abs(n);

    const int_part: u64 = @intFromFloat(abs_n);
    const frac_part = abs_n - @as(f64, @floatFromInt(int_part));

    var int_buf: [32]u8 = undefined;
    var int_len: usize = 0;

    if (int_part == 0) {
        int_buf[0] = '0';
        int_len = 1;
    } else {
        var temp = int_part;
        while (temp > 0) {
            int_buf[int_len] = @intCast((temp % 10) + '0');
            temp /= 10;
            int_len += 1;
        }
    }

    var i: usize = 0;
    var j: usize = int_len;
    while (i < j) {
        j -= 1;
        const tmp = int_buf[i];
        int_buf[i] = int_buf[j];
        int_buf[j] = tmp;
        i += 1;
    }

    var result = std.ArrayList(u8).init(allocator);
    errdefer result.deinit();

    if (negative) {
        try result.append('-');
    }

    var digit_count: usize = 0;
    const first_group_size = int_len % 3;
    const first_group = if (first_group_size == 0) 3 else first_group_size;

    for (int_buf[0..int_len]) |c| {
        if (digit_count > 0 and digit_count == first_group) {
            try result.append(config.thousand_sep);
            digit_count = 0;
        } else if (digit_count > 0 and digit_count > first_group and (digit_count - first_group) % 3 == 0) {
            try result.append(config.thousand_sep);
        }
        try result.append(c);
        digit_count += 1;
    }

    if (config.precision) |prec| {
        if (prec > 0 and frac_part > 0) {
            try result.append(config.decimal_sep);

            var frac = frac_part;
            var frac_digits: usize = 0;
            while (frac_digits < prec) {
                frac *= 10;
                const digit: u8 = @intFromFloat(@mod(frac, 10));
                try result.append(digit + '0');
                frac_digits += 1;
            }

            while (result.items.len > 0 and result.items[result.items.len - 1] == '0') {
                _ = result.pop();
            }
            if (result.items.len > 0 and result.items[result.items.len - 1] == config.decimal_sep) {
                _ = result.pop();
            }
        }
    }

    return result.toOwnedSlice();
}

test "formatFloat US format" {
    const allocator = std.testing.allocator;

    {
        const result = try formatFloat(allocator, "#,###.##", 12345.6789);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("12,345.67", result);
    }
    {
        const result = try formatFloat(allocator, "#,###.", 12345.6789);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("12,345", result);
    }
    {
        const result = try formatFloat(allocator, "", 12345.67);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("12,345.67", result);
    }
}

test "formatFloat European format" {
    const allocator = std.testing.allocator;

    {
        const result = try formatFloat(allocator, "#.###,##", 12345.6789);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("12.345,67", result);
    }
}

test "formatFloat negative" {
    const allocator = std.testing.allocator;

    {
        const result = try formatFloat(allocator, "#,###.##", -12345.67);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("-12,345.67", result);
    }
}

test "formatInteger" {
    const allocator = std.testing.allocator;

    {
        const result = try formatInteger(allocator, "#,###", 1000000);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("1,000,000", result);
    }
}
