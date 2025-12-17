# zig-humanize

[![Zig support](https://img.shields.io/badge/Zig-≥0.15.2-color?logo=zig&color=%23f3ab20)](https://ziglang.org/download/)
[![Release](https://img.shields.io/github/v/release/burdzwastaken/zig-humanize)](https://github.com/burdzwastaken/zig-humanize/releases)
[![CI Status](https://img.shields.io/github/actions/workflow/status/burdzwastaken/zig-humanize/ci.yml)](https://github.com/burdzwastaken/zig-humanize/actions)

Zig library for converting numbers and times to human-friendly strings

## Installation

```bash
zig fetch --save git+https://github.com/burdzwastaken/zig-humanize#v0.0.5
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
humanize.bytes.si(82854982)                  // "82.855 MB"
humanize.bytes.si(82854982).withPrecision(2) // "82.85 MB"
humanize.bytes.iec(82854982)                 // "79.017 MiB"
humanize.parseBytes("42 MB")                 // 42000000
humanize.parseBytes("42 MiB")                // 44040192

const msg     = humanize.comptimeBytes(4096);                     // "4.096 kB"
const iec     = humanize.comptimeIBytes(4096);                    // "4 KiB"
const precise = humanize.comptimeBytesWithPrecision(82854982, 2); // "82.85 MB"
```

### Comma

```zig
humanize.comma.int(1234567890)            // "1,234,567,890"
humanize.comma.float(1234567.89)          // "1,234,567.89"
humanize.comma.Float.european(1234567.89) // "1.234.567,89"
```

### Ordinals

```zig
humanize.ordinal(1)  // "1st"
humanize.ordinal(2)  // "2nd"
humanize.ordinal(3)  // "3rd"
humanize.ordinal(11) // "11th"
humanize.ordinal(21) // "21st"

const ord = humanize.comptimeOrdinal(42); // "42nd"
```

### SI Notation

```zig
humanize.siPrefix(1000000, "B")    // "1 MB"
humanize.siPrefix(2.2345e-12, "F") // "2.2345 pF"
humanize.parseSI("2.5 k")          // 2500.0

const si_msg  = humanize.comptimeSI(1000000, "B");                       // "1 MB"
const si_precise = humanize.comptimeSIWithPrecision(2.2345e-12, "F", 2); // "2.23 pF"
```

### Relative Time

```zig
humanize.relTime(now - humanize.Second, now, "ago", "from now")     // "1 second ago"
humanize.relTime(now - 5 * humanize.Minute, now, "ago", "from now") // "5 minutes ago"
humanize.relTime(now + 2 * humanize.Hour, now, "ago", "from now")   // "2 hours from now"
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

const word  = humanize.comptimePluralWord(5, "index", ""); // "indices"
const plural = humanize.comptimePlural(5, "cat", "");      // "5 cats"
```

## License

MIT

## Credits

Dustin Sallings for [go-humanize](https://github.com/dustin/go-humanize)!
