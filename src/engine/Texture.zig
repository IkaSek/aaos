const std = @import("std");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const Window = @import("Window.zig");
const fs = @import("fs.zig");

const this = @This();

allocator: std.mem.Allocator,
pixel_buffer: [][]u8,

sdl2_texture: *sdl2.SDL_Texture,
window: *Window,

/// textures have a max width of 256
const textures_max_width: usize = 256;
/// textures have a max height of 256
const textures_max_height: usize = 256;

pub fn init(window: *Window, filename: []const u8) !this {
    var texture: this = undefined;
    texture.window = window;
    texture.sdl2_texture = sdl2.SDL_CreateTexture(texture.window.sdl2_renderer, sdl2.SDL_PIXELFORMAT_RGB, sdl2.SDL_TEXTUREACCESS_STREAMING, textures_max_width, textures_max_height);
    const texture_dir_mgr: fs.dir_mgmt.TexturesDirMgr = fs.dir_mgmt.texuresDirMgr(null);
    const texture_file: std.fs.File = try texture_dir_mgr.findFile(filename);
    _ = texture_file;
}
