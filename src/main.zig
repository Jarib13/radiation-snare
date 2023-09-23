const std = @import("std");

const byte = 1;

const kilobyte = byte * 1000;
const megabyte = kilobyte * 1000;
const gigabyte = megabyte * 1000;

const kibibyte = byte * 1024;
const mibibyte = kibibyte * 1024;
const gibibyte = mibibyte * 1024;

fn generate_alternating_bits() u128 {
    var bits: u128 = 0;
    for (0..128) |bit| {
        if (bit % 2 == 0) {
            bits |= @as(u128, 1) <<| bit;
        }
    }

    return bits;
}

const alternating_bit_pattern = generate_alternating_bits();

test "bit_patterns" {
    std.debug.print("alternating = {b:O>128}\n", .{alternating_bit_pattern});
}

const Corruption = struct {
    time_discovered: i64,
    effected_element: usize,
    memory_address: usize,
    effected_bits: u128,
};

const BitMode = enum {
    Zeroes,
    Ones,
    Alternating,
};

const Sheet = struct {
    mode: BitMode = BitMode.Zeroes,
    bits: []u128,

    fn get_expected_bits(self: Sheet) u128 {
        return switch (self.mode) {
            .Zeroes => 0,
            .Ones => ~@as(u128, 0),
            .Alternating => alternating_bit_pattern,
        };
    }

    fn init(alloc: std.mem.Allocator, mode: BitMode, size: usize) !Sheet {
        var self = Sheet{
            .mode = mode,
            .bits = try alloc.alloc(u128, size / @sizeOf(u128)),
        };

        @memset(self.bits, self.get_expected_bits());

        return self;
    }
};

pub fn main() !void {
    var text_buffer: [1024]u8 = undefined;

    std.debug.print("Initializing radiation-snare... ", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    var sheets = std.ArrayList(Sheet).init(alloc);
    try sheets.append(try Sheet.init(alloc, BitMode.Zeroes, 1 * gigabyte));
    try sheets.append(try Sheet.init(alloc, BitMode.Alternating, 1 * gigabyte));
    try sheets.append(try Sheet.init(alloc, BitMode.Ones, 2 * gigabyte));

    var corruptions = std.ArrayList(Corruption).init(alloc);

    std.debug.print("Done\nBeginning periodic scans... \n", .{});

    sheets.items[0].bits[80085] |= 1 << 6;
    sheets.items[1].bits[8008135] |= 1 << 73;
    sheets.items[2].bits[69420] &= ~@as(u128, 1 << 44);

    var last_corruption_count: usize = 0;
    var scans: usize = 0;
    const scans_per_msg = 1;

    while (true) : (scans += 1) {
        defer std.time.sleep(std.time.ns_per_s * 300);

        if (scans % scans_per_msg == 0) {
            std.debug.print("Scanning...   ", .{});
        }

        var timer = try std.time.Timer.start();
        for (sheets.items) |sheet| {
            var expected_bits: u128 = sheet.get_expected_bits();

            for (sheet.bits, 0..) |*element, index| {
                if (element.* != expected_bits) {
                    try corruptions.append(Corruption{
                        .time_discovered = std.time.milliTimestamp(),
                        .effected_element = index,
                        .effected_bits = element.*,
                        .memory_address = @intFromPtr(element),
                    });
                    element.* = expected_bits;
                }
            }
        }

        if (scans % scans_per_msg == 0) {
            std.debug.print("Scan Complete in {} milliseconds -- {} corruptions found\n", .{ timer.lap() / std.time.ns_per_ms, corruptions.items.len - last_corruption_count });
        }

        if (last_corruption_count < corruptions.items.len) {
            std.debug.print("-- [Corruptions Discovered] --\n", .{});
            for (corruptions.items) |corruption| {
                var milliseconds_ago = (std.time.milliTimestamp() - corruption.time_discovered);
                var time_text: []u8 = undefined;

                if (milliseconds_ago > std.time.ms_per_day) {
                    time_text = try std.fmt.bufPrintZ(&text_buffer, "{d:4} days ago", .{@divFloor(milliseconds_ago, std.time.ms_per_day)});
                } else if (milliseconds_ago > std.time.ms_per_hour) {
                    time_text = try std.fmt.bufPrintZ(&text_buffer, "{d:3} hours ago", .{@divFloor(milliseconds_ago, std.time.ms_per_hour)});
                } else if (milliseconds_ago > std.time.ms_per_min) {
                    time_text = try std.fmt.bufPrintZ(&text_buffer, "{d:4} mins ago", .{@divFloor(milliseconds_ago, std.time.ms_per_min)});
                } else {
                    time_text = try std.fmt.bufPrintZ(&text_buffer, "{d:4} secs ago", .{@divFloor(milliseconds_ago, std.time.ms_per_s)});
                }

                std.debug.print("TimeDiscovered = {s:13} ElementIndex = #{d:<12} MemAddress = @{x:0>16} BITS={b:O>128}\n", .{
                    time_text,
                    corruption.effected_element,
                    corruption.memory_address,
                    corruption.effected_bits,
                });
            }
            std.debug.print("-- --\n\n", .{});

            last_corruption_count = corruptions.items.len;
        }
    }
}
