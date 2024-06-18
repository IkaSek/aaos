const std = @import("std");
const Texture = @import("Texture.zig");
const main = @import("../main.zig");

const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
});
const this = @This();

pub const WindowError = error{
    create_failed,
    event_poll_failed,
    render_failed,
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

pub fn renderTexture(self: *this, texture: Texture, x: usize, y: usize) void {
    const render_quad: sdl2.SDL_Rect = .{
        .x = x,
        .y = y,
        .w = texture.width,
        .h = texture.height,
    };
    sdl2.SDL_RenderCopy(self.sdl2_renderer, texture.sdl2_texture, null, &render_quad);
}

pub fn renderPresent(self: *this) void {
    sdl2.SDL_RenderPresent(self.sdl2_renderer);
}

pub fn destroy(self: *this) void {
    sdl2.SDL_DestroyRenderer(self.sdl2_renderer);
    sdl2.SDL_DestroyWindow(self.sdl2_window);
}
