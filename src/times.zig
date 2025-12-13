//! Relative time formatting ("3 days ago", "in 2 hours")

const std = @import("std");

/// Time duration constants in nanoseconds (compatible with std.time)
pub const Second: i64 = std.time.ns_per_s;
pub const Minute: i64 = 60 * Second;
pub const Hour: i64 = 60 * Minute;
pub const Day: i64 = 24 * Hour;
pub const Week: i64 = 7 * Day;
pub const Month: i64 = 30 * Day;
pub const Year: i64 = 365 * Day;
pub const LongTime: i64 = 37 * Year;

pub const RelTimeMagnitude = struct {
    duration: i64,
    format: Format,

    pub const Format = union(enum) {
        static: []const u8,
        quantity: struct {
            singular: []const u8,
            plural: []const u8,
            div_by: i64,
        },
    };
};

pub const default_magnitudes = [_]RelTimeMagnitude{
    .{ .duration = Second, .format = .{ .static = "now" } },
    .{ .duration = 2 * Second, .format = .{ .quantity = .{ .singular = "1 second", .plural = "1 second", .div_by = Second } } },
    .{ .duration = Minute, .format = .{ .quantity = .{ .singular = "second", .plural = "seconds", .div_by = Second } } },
    .{ .duration = 2 * Minute, .format = .{ .quantity = .{ .singular = "1 minute", .plural = "1 minute", .div_by = Minute } } },
    .{ .duration = Hour, .format = .{ .quantity = .{ .singular = "minute", .plural = "minutes", .div_by = Minute } } },
    .{ .duration = 2 * Hour, .format = .{ .quantity = .{ .singular = "1 hour", .plural = "1 hour", .div_by = Hour } } },
    .{ .duration = Day, .format = .{ .quantity = .{ .singular = "hour", .plural = "hours", .div_by = Hour } } },
    .{ .duration = 2 * Day, .format = .{ .quantity = .{ .singular = "1 day", .plural = "1 day", .div_by = Day } } },
    .{ .duration = Week, .format = .{ .quantity = .{ .singular = "day", .plural = "days", .div_by = Day } } },
    .{ .duration = 2 * Week, .format = .{ .quantity = .{ .singular = "1 week", .plural = "1 week", .div_by = Week } } },
    .{ .duration = Month, .format = .{ .quantity = .{ .singular = "week", .plural = "weeks", .div_by = Week } } },
    .{ .duration = 2 * Month, .format = .{ .quantity = .{ .singular = "1 month", .plural = "1 month", .div_by = Month } } },
    .{ .duration = Year, .format = .{ .quantity = .{ .singular = "month", .plural = "months", .div_by = Month } } },
    .{ .duration = 18 * Month, .format = .{ .quantity = .{ .singular = "1 year", .plural = "1 year", .div_by = Year } } },
    .{ .duration = 2 * Year, .format = .{ .quantity = .{ .singular = "2 years", .plural = "2 years", .div_by = Year } } },
    .{ .duration = LongTime, .format = .{ .quantity = .{ .singular = "year", .plural = "years", .div_by = Year } } },
    .{ .duration = std.math.maxInt(i64), .format = .{ .static = "a very long time" } },
};

/// Relative time formatter
pub const RelTime = struct {
    a: i64,
    b: i64,
    a_label: []const u8 = "ago",
    b_label: []const u8 = "from now",
    magnitudes: []const RelTimeMagnitude = &default_magnitudes,

    pub fn since(timestamp: i64) RelTime {
        return .{ .a = timestamp, .b = std.time.nanoTimestamp() };
    }

    pub fn between(a: i64, b: i64) RelTime {
        return .{ .a = a, .b = b };
    }

    pub fn withLabels(self: RelTime, a_label: []const u8, b_label: []const u8) RelTime {
        return .{
            .a = self.a,
            .b = self.b,
            .a_label = a_label,
            .b_label = b_label,
            .magnitudes = self.magnitudes,
        };
    }

    pub fn format(self: RelTime, w: *std.io.Writer) std.io.Writer.Error!void {
        var diff = self.a - self.b;
        const label = if (diff < 0) self.a_label else self.b_label;

        if (diff < 0) diff = -diff;

        for (self.magnitudes) |mag| {
            if (diff < mag.duration) {
                try formatMagnitude(w, mag, diff, label);
                return;
            }
        }

        try w.writeAll("a very long time");
        if (label.len > 0) {
            try w.print(" {s}", .{label});
        }
    }
};

fn formatMagnitude(w: *std.io.Writer, mag: RelTimeMagnitude, diff: i64, label: []const u8) std.io.Writer.Error!void {
    switch (mag.format) {
        .static => |s| {
            try w.writeAll(s);
        },
        .quantity => |q| {
            const quantity = @divTrunc(diff, q.div_by);
            if (quantity == 1 or std.mem.eql(u8, q.singular, q.plural)) {
                try w.print("{s} {s}", .{ q.singular, label });
            } else {
                try w.print("{d} {s} {s}", .{ quantity, q.plural, label });
            }
        },
    }
}

pub fn relTime(a: i64, b: i64, a_label: []const u8, b_label: []const u8) RelTime {
    return RelTime.between(a, b).withLabels(a_label, b_label);
}

test "relTime basic" {
    const base: i64 = 0;

    try std.testing.expectFmt("now", "{f}", .{relTime(base, base, "ago", "from now")});
    try std.testing.expectFmt("1 second ago", "{f}", .{relTime(base - Second, base, "ago", "from now")});
    try std.testing.expectFmt("30 seconds ago", "{f}", .{relTime(base - 30 * Second, base, "ago", "from now")});
    try std.testing.expectFmt("1 minute ago", "{f}", .{relTime(base - Minute, base, "ago", "from now")});
    try std.testing.expectFmt("5 minutes ago", "{f}", .{relTime(base - 5 * Minute, base, "ago", "from now")});
    try std.testing.expectFmt("1 hour ago", "{f}", .{relTime(base - Hour, base, "ago", "from now")});
    try std.testing.expectFmt("1 day ago", "{f}", .{relTime(base - Day, base, "ago", "from now")});
    try std.testing.expectFmt("1 week ago", "{f}", .{relTime(base - Week, base, "ago", "from now")});
    try std.testing.expectFmt("3 weeks ago", "{f}", .{relTime(base - 3 * Week, base, "ago", "from now")});
}

test "relTime future" {
    const base: i64 = 0;

    try std.testing.expectFmt("1 hour from now", "{f}", .{relTime(base + Hour, base, "ago", "from now")});
    try std.testing.expectFmt("3 days from now", "{f}", .{relTime(base + 3 * Day, base, "ago", "from now")});
}

test "relTime custom labels" {
    const base: i64 = 0;

    try std.testing.expectFmt("3 weeks earlier", "{f}", .{relTime(base - 3 * Week, base, "earlier", "later")});
}
