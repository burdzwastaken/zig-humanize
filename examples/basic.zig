const std = @import("std");
const humanize = @import("humanize");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    // Bytes
    try stdout.print("Bytes SI:  {d} -> {f}\n", .{ @as(u64, 82854982), humanize.Bytes.si(82854982) });
    try stdout.print("Bytes IEC: {d} -> {f}\n", .{ @as(u64, 82854982), humanize.Bytes.iec(82854982) });
    try stdout.print("Bytes precision(2): {f}\n", .{humanize.Bytes.si(82854982).withPrecision(2)});
    try stdout.print("Parse '42 MB': {d}\n", .{humanize.parseBytes("42 MB") catch 0});

    // Comma
    try stdout.print("Comma: {d} -> {f}\n", .{ @as(i64, 1234567890), humanize.comma_(1234567890) });
    try stdout.print("CommaFloat: {d} -> {f}\n", .{ @as(f64, 1234567.89), humanize.commaFloat(1234567.89) });

    // Ordinals
    try stdout.print("Ordinals: {f}, {f}, {f}, {f}, {f}\n", .{
        humanize.ordinal(1),
        humanize.ordinal(2),
        humanize.ordinal(3),
        humanize.ordinal(11),
        humanize.ordinal(21),
    });

    // SI notation
    try stdout.print("SI: {d} B -> {f}\n", .{ @as(f64, 1000000.0), humanize.siPrefix(1000000, "B") });
    try stdout.print("SI: {e} F -> {f}\n", .{ @as(f64, 2.2345e-12), humanize.siPrefix(2.2345e-12, "F") });

    // Relative time
    const now: i64 = 0;
    try stdout.print("RelTime: {f}\n", .{humanize.relTime(now - humanize.Second, now, "ago", "from now")});
    try stdout.print("RelTime: {f}\n", .{humanize.relTime(now - 5 * humanize.Minute, now, "ago", "from now")});
    try stdout.print("RelTime: {f}\n", .{humanize.relTime(now + 2 * humanize.Hour, now, "ago", "from now")});

    // Float formatting
    try stdout.print("Float: 2.24 -> {f}, 2.0 -> {f}\n", .{ humanize.floatToString(2.24), humanize.floatToString(2.0) });
    try stdout.print("Float precision(2): 3.14159 -> {f}\n", .{humanize.floatToStringWithPrecision(3.14159, 2)});

    // Pluralization
    try stdout.print("Plural: {f}, {f}\n", .{ humanize.plural(1, "object"), humanize.plural(42, "object") });

    // Word series
    const words = [_][]const u8{ "apples", "oranges", "bananas" };
    try stdout.print("WordSeries: {f}\n", .{humanize.wordSeries(&words)});
    try stdout.print("Oxford: {f}\n", .{humanize.oxfordWordSeries(&words)});

    // Comptime
    const comptime_ordinal = comptime humanize.ordinals.comptimeOrdinal(42);
    const comptime_plural = comptime humanize.english.comptimePluralWord(5, "index", "");
    try stdout.print("Comptime: {s}, {s}\n", .{ comptime_ordinal, comptime_plural });

    try stdout_writer.end();
}
