# Radiation Snare

## Download

There is a link to releases on the right side of this page.
- For windows, download radiation-snare.exe
- For linux, download radiation-snare

You can also build from source using the following command:

`zig build -Doptimize=ReleaseFast run`

I am not sure if optimizations will optimize out the hit checks, because these bits are never flipped by the program itself.
Alternativelty build in debug mode to ensure nothing is optimized away:
`zig build run`

Code written for Zig version 0.12.0-dev.21+ac95cfe44

## Run

File location doesn't matter, just run it anywhere.
When you run it initially, 3 bits will be flipped to test program is working as expected and to show what radiation bit flips would look like.

Periodically (every 5 minutes) each bit in the "sheet" will be checked for hits.
Every time a bit is flipped, it will be recorded.
Whenever a new hit is added, it and all other events will be printed to the console.

## Sheet Layout

The first sheet is 2gb and consists of all zeroes
The second sheet is 1gb and consists of alternating ones and zeros (01010101...)
The third sheet is 1gb and consists of all ones

The sheet contents are continous in memory, but the sheets themselves are not continuous in memory