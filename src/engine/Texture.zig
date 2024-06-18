const std = @import("std");
const builtin = @import("builtin");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const webp = @cImport({
    @cInclude("webp/decode.h");
});
const Window = @import("Window.zig");

const this = @This();

pub const TextureError = error{
    sdl_create_error,
    webp_parse_error,
};

pixel_buffer: []const u8,

/// the sdl texture
sdl2_texture: *sdl2.SDL_Texture,
/// the sdl surface
sdl2_surface: *sdl2.SDL_Surface,
/// the texture width and height
width: usize,
height: usize,
/// the Window.zig context
window: *Window,

pub fn init(window: *Window, filename: []const u8) !this {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var texture: this = undefined;
    texture.window = window;

    const appdata_dir_path: []u8 = std.fs.getAppDataDir(allocator, "aaos");
    defer allocator.free(appdata_dir_path);
    const appdata_dir: std.fs.Dir = std.fs.openDirAbsolute(.{}, appdata_dir_path);
    defer appdata_dir.close();

    const textures_dir: std.fs.Dir = appdata_dir.openDir("textures", .{});
    defer textures_dir.close();

    var texture_file: std.fs.File = try textures_dir.open(filename);

    defer texture_file.close();
    const texture_file_end: u64 = try texture_file.getEndPos();

    const interim_buffer: []u8 = try allocator(u8, texture_file_end);
    defer allocator.free(interim_buffer);
    _ = try texture_file.readAll(interim_buffer);

    var width: u32 = undefined;
    var height: u32 = undefined;
    const data: ?[]const u8 = webp.WebPDecodeARGB(interim_buffer, interim_buffer.len, &width, &height);
    if (data == null) {
        return TextureError.webp_parse_error;
    }
    texture.pixel_buffer = data;

    texture.sdl2_texture = sdl2.SDL_CreateTexture(texture.window.sdl2_renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_STATIC, width, height);
    errdefer sdl2.SDL_DestroyTexture(texture.sdl2_texture);
    if (texture.sdl2_texture == null) {
        return TextureError.sdl_create_error;
    }

    if (sdl2.SDL_UpdateTexture(texture.sdl2_texture, null, data, width * 4) != 0) {
        return TextureError.sdl_create_error;
    }
    return texture;
}

pub fn destroy(self: *this) void {
    sdl2.SDL_DestroyTexture(self.sdl2_texture);
}
