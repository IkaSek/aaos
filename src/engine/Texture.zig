const std = @import("std");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const Window = @import("Window.zig");

const this = @This();

sdl2_texture: *sdl2.SDL_Texture,
window: *Window,

pub fn init(window: *Window, filename: []const u8) !this {
    var texture: this = undefined;
    texture.window = window;
    texture.sdl2_texture = sdl2.SDL_CreateTexture(texture.window.sdl2_renderer, sdl2.SDL_PNG, access: c_int, w: c_int, h: c_int)
}
