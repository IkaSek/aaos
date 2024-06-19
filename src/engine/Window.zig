const std = @import("std");
const texture = @import("texture.zig");
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

pub fn init(name: []const u8) !this {
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

pub fn renderTexture(self: *this, text: texture.SimpleTexture, x: usize, y: usize) void {
    const render_quad: sdl2.SDL_Rect = .{
        .x = x,
        .y = y,
        .w = texture.width,
        .h = texture.height,
    };
    sdl2.SDL_RenderCopy(self.sdl2_renderer, text.sdl2_texture, null, &render_quad);
}

pub fn renderFontString(self: *this, font: texture.FontTexture, string: []const u8, x: usize, y: usize) !void {
    var render_offset_x: usize = 0;
    for (string, 0..) |char, i| {
        const render_quad: sdl2.SDL_Rect = .{
            .x = x + render_offset_x,
            .y = y,
            .w = texture.FontTexture.font_width,
            .h = texture.FontTexture.font_height,
        };
        sdl2.SDL_RenderCopy(self.sdl2_renderer, font.glyphs.items[char - 32], null, &render_quad);
        render_offset_x += i * texture.FontTexture.font_width;
    }
}

pub fn renderPresent(self: *this) void {
    sdl2.SDL_RenderPresent(self.sdl2_renderer);
}

pub fn destroy(self: *this) void {
    sdl2.SDL_DestroyRenderer(self.sdl2_renderer);
    sdl2.SDL_DestroyWindow(self.sdl2_window);
}
