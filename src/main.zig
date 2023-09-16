const std = @import("std");

const byte = 1;

const kilobyte = byte * 1000;
const megabyte = kilobyte * 1000;
const gigabyte = megabyte * 1000;

const kibibyte = byte * 1024;
const mibibyte = kibibyte * 1024;
const gibibyte = mibibyte * 1024;

const Corruption = struct {
    time_discovered: i64,
    effected_element: usize,
    memory_address: usize,
    effected_bits: u128,
};

pub fn main() !void {
    var text_buffer: [1024]u8 = undefined;

    std.debug.print("Initializing radiation-snare...\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    var sheet = try alloc.alloc(u128, (4 * gigabyte) / @sizeOf(u128));
    @memset(sheet, 0);

    var corruptions = std.ArrayList(Corruption).init(alloc);

    std.debug.print("Radiation-snare initialized, beginning periodic scans\n", .{});

    sheet[80085] = 1 << 6;
    sheet[8008135] = 1 << 73;
    sheet[69420] = 1 << 44;

    var last_corruption_count: usize = 0;
    var scans: usize = 0;
    const scans_per_msg = 1;
    while (true) : (scans += 1) {
        defer std.time.sleep(std.time.ns_per_s * 300);

        if (scans % scans_per_msg == 0) {
            std.debug.print("Scanning...   ", .{});
        }

        var timer = try std.time.Timer.start();
        for (sheet, 0..) |*element, index| {
            if (element.* != 0) {
                try corruptions.append(Corruption{
                    .time_discovered = std.time.milliTimestamp(),
                    .effected_element = index,
                    .effected_bits = element.*,
                    .memory_address = @intFromPtr(element),
                });
                element.* = 0;
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