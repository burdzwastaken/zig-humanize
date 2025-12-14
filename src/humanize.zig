//! Humanize: convert numbers and times to human-friendly strings

pub const bytes = @import("bytes.zig");
pub const comma = @import("comma.zig");
pub const english = @import("english.zig");
pub const ftoa = @import("ftoa.zig");
pub const ordinals = @import("ordinals.zig");
pub const si = @import("si.zig");
pub const times = @import("times.zig");

pub const Bytes = bytes.Bytes;
pub const siBytes = bytes.si;
pub const iecBytes = bytes.iec;
pub const Byte = bytes.Byte;
pub const KiByte = bytes.KiByte;
pub const MiByte = bytes.MiByte;
pub const GiByte = bytes.GiByte;
pub const TiByte = bytes.TiByte;
pub const PiByte = bytes.PiByte;
pub const EiByte = bytes.EiByte;
pub const KByte = bytes.KByte;
pub const MByte = bytes.MByte;
pub const GByte = bytes.GByte;
pub const TByte = bytes.TByte;
pub const PByte = bytes.PByte;
pub const EByte = bytes.EByte;
pub const parseBytes = bytes.parseBytes;
pub const comptimeBytes = bytes.comptimeBytes;
pub const comptimeIBytes = bytes.comptimeIBytes;
pub const comptimeBytesWithPrecision = bytes.comptimeBytesWithPrecision;
pub const comptimeIBytesWithPrecision = bytes.comptimeIBytesWithPrecision;

pub const plural = english.plural;
pub const pluralWord = english.pluralWord;
pub const wordSeries = english.wordSeries;
pub const oxfordWordSeries = english.oxfordWordSeries;

pub const floatToString = ftoa.floatToString;
pub const floatToStringWithPrecision = ftoa.floatToStringWithPrecision;

pub const ordinal = ordinals.ordinal;
pub const ordinalSuffix = ordinals.ordinalSuffix;
pub const comptimeOrdinal = ordinals.comptimeOrdinal;

pub const siPrefix = si.si;
pub const computeSI = si.computeSI;
pub const parseSI = si.parseSI;
pub const comptimeSI = si.comptimeSI;
pub const comptimeSIWithPrecision = si.comptimeSIWithPrecision;

pub const default_magnitudes = times.default_magnitudes;
pub const Second = times.Second;
pub const Minute = times.Minute;
pub const Hour = times.Hour;
pub const Day = times.Day;
pub const Week = times.Week;
pub const Month = times.Month;
pub const Year = times.Year;
pub const LongTime = times.LongTime;
pub const relTime = times.relTime;
pub const RelTimeMagnitude = times.RelTimeMagnitude;

test {
    @import("std").testing.refAllDecls(@This());
}
