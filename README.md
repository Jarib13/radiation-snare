# Radiation Snare

## Download

There is a link to releases on the left side of this page.
- For windows, download radiation-snare.exe
- For linux, download radiation-snare

You can also build from source using the following command:

`zig build -Doptimize=ReleaseFast run`

Code written for Zig version 0.12.0-dev.21+ac95cfe44

## Run

File location doesn't matter, just run it anywhere.
When you run it initially, 3 bits will be flipped to test program is working as expected and to show what radiation bit flips would look like.

4 gigabytes will be set to all zeros, and periodically (every 5 minutes) every bit in the 4gb "sheet" will be checked for hits.
Every time a bit is flipped, it will be recorded.
Whenever a new hit is added, it and all other events will be printed to the console.
