//! Comma formatting for numbers with thousand separators

const std = @import("std");
const ftoa = @import("ftoa.zig");

const Writer = std.Io.Writer;

/// Integer comma formatter
pub const Comma = struct {
    value: i64,
    separator: u8 = ',',

    pub fn init(value: i64) Comma {
        return .{ .value = value };
    }

    pub fn withSeparator(self: Comma, sep: u8) Comma {
        return .{ .value = self.value, .separator = sep };
    }

    pub fn format(self: Comma, w: *Writer) Writer.Error!void {
        if (self.value == 0) {
            try w.writeByte('0');
            return;
        }

        const negative = self.value < 0;
        var n: u64 = if (negative) @intCast(-self.value) else @intCast(self.value);

        var digits: [20]u8 = undefined;
        var len: usize = 0;

        while (n > 0) {
            digits[len] = @intCast((n % 10) + '0');
            n /= 10;
            len += 1;
        }

        if (negative) {
            try w.writeByte('-');
        }

        var i: usize = len;
        while (i > 0) {
            i -= 1;
            try w.writeByte(digits[i]);
            if (i > 0 and i % 3 == 0) {
                try w.writeByte(self.separator);
            }
        }
    }
};

/// Float comma formatter
pub const CommaFloat = struct {
    value: f64,
    separator: u8 = ',',
    decimal: u8 = '.',
    precision: ?u8 = null,

    pub fn init(value: f64) CommaFloat {
        return .{ .value = value };
    }

    pub fn withSeparator(self: CommaFloat, sep: u8) CommaFloat {
        return .{ .value = self.value, .separator = sep, .decimal = self.decimal, .precision = self.precision };
    }

    pub fn withDecimal(self: CommaFloat, dec: u8) CommaFloat {
        return .{ .value = self.value, .separator = self.separator, .decimal = dec, .precision = self.precision };
    }

    pub fn withPrecision(self: CommaFloat, p: u8) CommaFloat {
        return .{ .value = self.value, .separator = self.separator, .decimal = self.decimal, .precision = p };
    }

    /// European format: `1.234,56`
    pub fn european(value: f64) CommaFloat {
        return CommaFloat{ .value = value, .separator = '.', .decimal = ',' };
    }

    pub fn format(self: CommaFloat, w: *Writer) Writer.Error!void {
        if (try ftoa.writeSpecialFloat(w, ftoa.classifyFloat(self.value))) return;

        var num_buf: [ftoa.max_buf_size]u8 = undefined;
        const precision: u8 = self.precision orelse 6;
        const num_str = ftoa.bufPrintFloat(&num_buf, @abs(self.value), precision);

        const dot_pos = std.mem.indexOf(u8, num_str, ".") orelse num_str.len;
        const int_str = num_str[0..dot_pos];
        const frac_str = if (dot_pos < num_str.len) num_str[dot_pos + 1 ..] else "";

        if (self.value < 0) {
            try w.writeByte('-');
        }

        for (int_str, 0..) |c, i| {
            try w.writeByte(c);
            const pos_from_end = int_str.len - i - 1;
            if (pos_from_end > 0 and pos_from_end % 3 == 0) {
                try w.writeByte(self.separator);
            }
        }

        if (frac_str.len > 0) {
            var end = frac_str.len;
            if (self.precision == null) {
                while (end > 0 and frac_str[end - 1] == '0') {
                    end -= 1;
                }
            }
            if (end > 0) {
                try w.writeByte(self.decimal);
                try w.writeAll(frac_str[0..end]);
            }
        }
    }
};

pub fn comma(value: i64) Comma {
    return Comma.init(value);
}

pub fn commaFloat(value: f64) CommaFloat {
    return CommaFloat.init(value);
}

test "comma integers" {
    try std.testing.expectFmt("0", "{f}", .{comma(0)});
    try std.testing.expectFmt("100", "{f}", .{comma(100)});
    try std.testing.expectFmt("1,000", "{f}", .{comma(1000)});
    try std.testing.expectFmt("1,000,000", "{f}", .{comma(1000000)});
    try std.testing.expectFmt("1,000,000,000", "{f}", .{comma(1000000000)});
    try std.testing.expectFmt("-100,000", "{f}", .{comma(-100000)});
}

test "commaFloat" {
    try std.testing.expectFmt("834,142.32", "{f}", .{commaFloat(834142.32)});
    try std.testing.expectFmt("1,000", "{f}", .{commaFloat(1000.0)});
    try std.testing.expectFmt("-1,234,567.89", "{f}", .{commaFloat(-1234567.89)});
}

test "commaFloat european" {
    try std.testing.expectFmt("834.142,32", "{f}", .{CommaFloat.european(834142.32)});
}
