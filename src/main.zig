const std = @import("std");
const engine = @import("engine.zig");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
});

const aaos_version = "0-indev";
const aaos_window_name = "AAoS: indev";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try engine.init(allocator);
    defer engine.destroy();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    const args = argv[1..];
    if (args.len > 0) {
        const stdout = std.io.getStdOut();
        defer stdout.close();
        for (args) |arg| {
            if (std.mem.eql(u8, "-v", arg) or std.mem.eql(u8, "--version", arg)) {
                try stdout.writer().print("{s}\n", .{aaos_version});
                return;
            } else if (std.mem.eql(u8, "-p", arg) or std.mem.eql(u8, "--project", arg)) {
                try stdout.writer().print("{s}\n", .{aaos_window_name});
                return;
            } else if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
                try stdout.writer().print("{s}\n", .{
                    \\-v|--version: AAoS version
                    \\-p|--project: AAoS project/window name
                    \\-h|--help   : This message
                });
                return;
            }
        }
    }

    if (sdl2.SDL_Init(sdl2.SDL_INIT_EVERYTHING) != 0) {
        std.log.err("sdl init failed", .{});
    }
    defer sdl2.SDL_Quit();

    var window: engine.Window = try engine.Window.init(aaos_window_name);
    defer window.destroy();

    var is_open: bool = true;
    var event: sdl2.SDL_Event = undefined;

    while (is_open == true) {
        if (sdl2.SDL_PollEvent(&event) == 0) {
            break;
        }
        switch (event.type) {
            sdl2.SDL_QUIT => is_open = false,
            else => continue,
        }
    }
}
