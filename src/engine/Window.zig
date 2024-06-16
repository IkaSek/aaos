const std = @import("std");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
});
const main = @import("main.zig");
const this = @This();

pub const WindowError = error{
    create_failed,
    event_poll_failed,
};

sdl2_window: *sdl2.SDL_Window,
sdl2_renderer: *sdl2.SDL_Renderer,

pub fn init(name: []const u8) WindowError!this {
    var window: this = undefined;
    std.log.info("creating sdl2 window", .{});
    window.sdl2_window = sdl2.SDL_CreateWindow(@ptrCast(name.ptr), sdl2.SDL_WINDOWPOS_UNDEFINED, sdl2.SDL_WINDOWPOS_UNDEFINED, 600, 800, sdl2.SDL_WINDOW_SHOWN) orelse {
        std.log.err("sdl2 window creation failed: {s}", .{sdl2.SDL_GetError()});
        return WindowError.create_failed;
    };

    std.log.info("creating sdl2 renderer", .{});
    window.sdl2_renderer = sdl2.SDL_CreateRenderer(window.sdl2_window, -1, sdl2.SDL_RENDERER_ACCELERATED | sdl2.SDL_RENDERER_PRESENTVSYNC) orelse {
        std.log.err("sdl2 renderer creation failed: {s}", .{sdl2.SDL_GetError()});
        return WindowError.create_failed;
    };

    return window;
}

pub fn destroy(self: *this) void {
    sdl2.SDL_DestroyRenderer(self.sdl2_renderer);
    sdl2.SDL_DestroyWindow(self.sdl2_window);
}
