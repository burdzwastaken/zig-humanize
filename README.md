# zig-humanize

[![Zig support](https://img.shields.io/badge/Zig-≥0.15.2-color?logo=zig&color=%23f3ab20)](https://ziglang.org/download/)
[![Release](https://img.shields.io/github/v/release/burdzwastaken/zig-humanize)](https://github.com/burdzwastaken/zig-humanize/releases)
[![CI Status](https://img.shields.io/github/actions/workflow/status/burdzwastaken/zig-humanize/ci.yml)](https://github.com/burdzwastaken/zig-humanize/actions)

Zig library for converting numbers and times to human-friendly strings

## Installation

```bash
zig fetch --save git+https://github.com/burdzwastaken/zig-humanize#v0.0.1
```

Then in your `build.zig`:

```zig
const humanize = b.dependency("humanize", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("humanize", humanize.module("humanize"));
```

## API

### Bytes

```zig
humanize.Bytes.si(82854982)                  // "82.855 MB"
humanize.Bytes.si(82854982).withPrecision(2) // "82.85 MB"
humanize.Bytes.iec(82854982)                 // "79.017 MiB"
humanize.parseBytes("42 MB")                 // 42000000
humanize.parseBytes("42 MiB")                // 44040192
```

### Comma

```zig
humanize.comma_(1234567890)                    // "1,234,567,890"
humanize.commaFloat(1234567.89)                // "1,234,567.89"
humanize.comma.CommaFloat.european(1234567.89) // "1.234.567,89"
```

### Ordinals

```zig
humanize.ordinal(1)  // "1st"
humanize.ordinal(2)  // "2nd"
humanize.ordinal(3)  // "3rd"
humanize.ordinal(11) // "11th"
humanize.ordinal(21) // "21st"

comptime humanize.ordinals.comptimeOrdinal(42) // "42nd"
```

### SI Notation

```zig
humanize.siPrefix(1000000, "B")    // "1 MB"
humanize.siPrefix(2.2345e-12, "F") // "2.2345 pF"
humanize.parseSI("2.5 k")          // 2500.0
```

### Relative Time

```zig
humanize.relTime(now - humanize.Second, now, "ago", "from now")     // "1 second ago"
humanize.relTime(now - 5 * humanize.Minute, now, "ago", "from now") // "5 minutes ago"
humanize.relTime(now + 2 * humanize.Hour, now, "ago", "from now")   // "2 hours from now"

// Constants: Second, Minute, Hour, Day, Week, Month, Year, LongTime
```

### Float

```zig
humanize.floatToString(2.24)                    // "2.24"
humanize.floatToString(2.0)                     // "2"
humanize.floatToStringWithPrecision(3.14159, 2) // "3.14"
```

### English

```zig
humanize.plural(1, "object")  // "1 object"
humanize.plural(42, "object") // "42 objects"
humanize.pluralWord(2, "bus") // "buses"

humanize.wordSeries(&.{ "foo", "bar", "baz" })       // "foo, bar and baz"
humanize.oxfordWordSeries(&.{ "foo", "bar", "baz" }) // "foo, bar, and baz"

comptime humanize.english.comptimePluralWord(5, "index", "") // "indices"
```

## License

MIT

## Credits

Dustin Sallings for [go-humanize](https://github.com/dustin/go-humanize)!
