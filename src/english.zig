//! English pluralization and word series formatting

const std = @import("std");

/// Comptime pluralization with automatic rules and special cases
pub fn comptimePluralWord(comptime quantity: i64, comptime singular: []const u8, comptime plural_override: []const u8) []const u8 {
    if (quantity == 1 or quantity == -1) {
        return singular;
    }

    if (plural_override.len > 0) {
        return plural_override;
    }

    return comptimeAutoPluralize(singular);
}

fn comptimeAutoPluralize(comptime word: []const u8) []const u8 {
    if (word.len == 0) return "";

    const special = getSpecialPlural(word);
    if (special) |s| return s;

    const last = word[word.len - 1];
    const last_two = if (word.len >= 2) word[word.len - 2 ..] else "";

    if (last == 's' or last == 'x' or last == 'z') {
        return word ++ "es";
    }
    if (std.mem.eql(u8, last_two, "sh") or std.mem.eql(u8, last_two, "ch")) {
        return word ++ "es";
    }
    if (last == 'y' and word.len >= 2 and !isVowel(word[word.len - 2])) {
        return word[0 .. word.len - 1] ++ "ies";
    }
    if (last == 'o' and word.len >= 2 and !isVowel(word[word.len - 2])) {
        if (isOException(word)) {
            return word ++ "s";
        }
        return word ++ "es";
    }
    if (last == 'f') {
        return word[0 .. word.len - 1] ++ "ves";
    }
    if (std.mem.eql(u8, last_two, "fe")) {
        return word[0 .. word.len - 2] ++ "ves";
    }
    return word ++ "s";
}

fn isVowel(c: u8) bool {
    return switch (c) {
        'a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U' => true,
        else => false,
    };
}

fn isOException(comptime word: []const u8) bool {
    const exceptions = [_][]const u8{ "photo", "piano", "halo", "zero", "auto", "memo", "solo" };
    for (exceptions) |exc| {
        if (eqlIgnoreCase(word, exc)) return true;
    }
    return false;
}

fn getSpecialPlural(comptime word: []const u8) ?[]const u8 {
    const specials = [_]struct { s: []const u8, p: []const u8 }{
        .{ .s = "index", .p = "indices" },
        .{ .s = "matrix", .p = "matrices" },
        .{ .s = "vertex", .p = "vertices" },
        .{ .s = "radius", .p = "radii" },
        .{ .s = "focus", .p = "foci" },
        .{ .s = "nucleus", .p = "nuclei" },
        .{ .s = "syllabus", .p = "syllabi" },
        .{ .s = "fungus", .p = "fungi" },
        .{ .s = "cactus", .p = "cacti" },
        .{ .s = "thesis", .p = "theses" },
        .{ .s = "crisis", .p = "crises" },
        .{ .s = "phenomenon", .p = "phenomena" },
        .{ .s = "criterion", .p = "criteria" },
        .{ .s = "datum", .p = "data" },
        .{ .s = "child", .p = "children" },
        .{ .s = "person", .p = "people" },
        .{ .s = "man", .p = "men" },
        .{ .s = "woman", .p = "women" },
        .{ .s = "foot", .p = "feet" },
        .{ .s = "tooth", .p = "teeth" },
        .{ .s = "goose", .p = "geese" },
        .{ .s = "mouse", .p = "mice" },
        .{ .s = "louse", .p = "lice" },
        .{ .s = "ox", .p = "oxen" },
    };

    for (specials) |sp| {
        if (eqlIgnoreCase(word, sp.s)) return sp.p;
    }
    return null;
}

fn eqlIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ac, bc| {
        const al = if (ac >= 'A' and ac <= 'Z') ac + 32 else ac;
        const bl = if (bc >= 'A' and bc <= 'Z') bc + 32 else bc;
        if (al != bl) return false;
    }
    return true;
}

/// Formatter for pluralized words
pub const PluralWord = struct {
    quantity: i64,
    singular: []const u8,
    plural_override: []const u8 = "",

    pub fn init(quantity: i64, singular: []const u8) PluralWord {
        return .{ .quantity = quantity, .singular = singular };
    }

    pub fn withPlural(self: PluralWord, p: []const u8) PluralWord {
        return .{ .quantity = self.quantity, .singular = self.singular, .plural_override = p };
    }

    pub fn format(self: PluralWord, w: *std.io.Writer) std.io.Writer.Error!void {
        if (self.quantity == 1 or self.quantity == -1) {
            try w.writeAll(self.singular);
        } else if (self.plural_override.len > 0) {
            try w.writeAll(self.plural_override);
        } else {
            try runtimePluralize(w, self.singular);
        }
    }
};

fn runtimePluralize(w: *std.io.Writer, word: []const u8) std.io.Writer.Error!void {
    if (word.len == 0) return;

    const last = word[word.len - 1];

    if (last == 's' or last == 'x' or last == 'z') {
        try w.print("{s}es", .{word});
    } else if (last == 'y' and word.len >= 2 and !isVowel(word[word.len - 2])) {
        try w.print("{s}ies", .{word[0 .. word.len - 1]});
    } else {
        try w.print("{s}s", .{word});
    }
}

/// Formatter for quantity + plural word
pub const Plural = struct {
    quantity: i64,
    singular: []const u8,
    plural_override: []const u8 = "",

    pub fn init(quantity: i64, singular: []const u8) Plural {
        return .{ .quantity = quantity, .singular = singular };
    }

    pub fn withPlural(self: Plural, p: []const u8) Plural {
        return .{ .quantity = self.quantity, .singular = self.singular, .plural_override = p };
    }

    pub fn format(self: Plural, w: *std.io.Writer) std.io.Writer.Error!void {
        try w.print("{d} ", .{self.quantity});
        const pw = PluralWord{ .quantity = self.quantity, .singular = self.singular, .plural_override = self.plural_override };
        try pw.format(w);
    }
};

pub fn pluralWord(quantity: i64, singular: []const u8) PluralWord {
    return PluralWord.init(quantity, singular);
}

pub fn plural(quantity: i64, singular: []const u8) Plural {
    return Plural.init(quantity, singular);
}

/// Word series formatter
pub const WordSeries = struct {
    words: []const []const u8,
    conjunction: []const u8 = "and",
    oxford: bool = false,

    pub fn init(words: []const []const u8) WordSeries {
        return .{ .words = words };
    }

    pub fn withConjunction(self: WordSeries, conj: []const u8) WordSeries {
        return .{ .words = self.words, .conjunction = conj, .oxford = self.oxford };
    }

    pub fn withOxfordComma(self: WordSeries) WordSeries {
        return .{ .words = self.words, .conjunction = self.conjunction, .oxford = true };
    }

    pub fn format(self: WordSeries, w: *std.io.Writer) std.io.Writer.Error!void {
        if (self.words.len == 0) return;

        if (self.words.len == 1) {
            try w.writeAll(self.words[0]);
            return;
        }

        if (self.words.len == 2) {
            try w.print("{s} {s} {s}", .{ self.words[0], self.conjunction, self.words[1] });
            return;
        }

        for (self.words[0 .. self.words.len - 1], 0..) |word, i| {
            try w.writeAll(word);
            if (i < self.words.len - 2) {
                try w.writeAll(", ");
            } else if (self.oxford) {
                try w.print(", {s} ", .{self.conjunction});
            } else {
                try w.print(" {s} ", .{self.conjunction});
            }
        }
        try w.writeAll(self.words[self.words.len - 1]);
    }
};

pub fn wordSeries(words: []const []const u8) WordSeries {
    return WordSeries.init(words);
}

pub fn oxfordWordSeries(words: []const []const u8) WordSeries {
    return WordSeries.init(words).withOxfordComma();
}

test "comptime plural" {
    try std.testing.expectEqualStrings("object", comptimePluralWord(1, "object", ""));
    try std.testing.expectEqualStrings("objects", comptimePluralWord(42, "object", ""));
    try std.testing.expectEqualStrings("buses", comptimePluralWord(2, "bus", ""));
    try std.testing.expectEqualStrings("loci", comptimePluralWord(99, "locus", "loci"));
}

test "comptime special plurals" {
    try std.testing.expectEqualStrings("indices", comptimePluralWord(2, "index", ""));
    try std.testing.expectEqualStrings("matrices", comptimePluralWord(2, "matrix", ""));
    try std.testing.expectEqualStrings("vertices", comptimePluralWord(2, "vertex", ""));
}

test "comptime y ending" {
    try std.testing.expectEqualStrings("babies", comptimePluralWord(2, "baby", ""));
    try std.testing.expectEqualStrings("keys", comptimePluralWord(2, "key", ""));
}

test "plural formatter" {
    try std.testing.expectFmt("1 object", "{f}", .{plural(1, "object")});
    try std.testing.expectFmt("42 objects", "{f}", .{plural(42, "object")});
}

test "wordSeries" {
    const words1 = [_][]const u8{"foo"};
    try std.testing.expectFmt("foo", "{f}", .{wordSeries(&words1)});

    const words2 = [_][]const u8{ "foo", "bar" };
    try std.testing.expectFmt("foo and bar", "{f}", .{wordSeries(&words2)});

    const words3 = [_][]const u8{ "foo", "bar", "baz" };
    try std.testing.expectFmt("foo, bar and baz", "{f}", .{wordSeries(&words3)});
}

test "oxfordWordSeries" {
    const words = [_][]const u8{ "foo", "bar", "baz" };
    try std.testing.expectFmt("foo, bar, and baz", "{f}", .{oxfordWordSeries(&words)});
}
