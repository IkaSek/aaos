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
const state = @import("state.zig");

pub const SimpleTexture = struct {
    const this = @This();
    pub const SimpleTextureError = error{
        sdl_init_error,
        webp_parse_error,
    };
    usingnamespace this;
    pixel_buffer: []const u8,

    /// the sdl texture
    sdl2_texture: *sdl2.SDL_Texture,
    /// the texture width and height
    width: usize,
    height: usize,

    pub fn init(window: Window, filename: []const u8) !this {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var texture: this = undefined;
        texture.window = window;

        const textures_dir: std.fs.Dir = state.appdata_dir.openDir("textures", .{});
        defer textures_dir.close();

        var texture_file: std.fs.File = try textures_dir.open(filename);

        defer texture_file.close();
        const texture_file_end: u64 = try texture_file.getEndPos();

        const interim_buffer: []u8 = try allocator(u8, texture_file_end);
        defer allocator.free(interim_buffer);
        _ = try texture_file.readAll(interim_buffer);

        var width: u32 = undefined;
        var height: u32 = undefined;
        const data: []const u8 = webp.WebPDecodeARGB(interim_buffer, interim_buffer.len, &width, &height) orelse {
            return SimpleTextureError.webp_parse_error;
        };
        texture.pixel_buffer = data;

        texture.sdl2_texture = sdl2.SDL_CreateTexture(texture.window.sdl2_renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_STATIC, width, height);
        errdefer sdl2.SDL_DestroyTexture(texture.sdl2_texture);
        if (texture.sdl2_texture == null) {
            return SimpleTextureError.sdl_create_error;
        }

        if (sdl2.SDL_UpdateTexture(texture.sdl2_texture, null, data, width * 4) != 0) {
            return SimpleTextureError.sdl_create_error;
        }
        return texture;
    }

    /// the function takes in w and h because we don't know the width and height, kindof.
    pub fn initPixels(window: Window, pixels: []const u8, w: usize, h: usize) !this {
        var texture: this = undefined;
        texture.pixel_buffer = pixels;
        texture.sdl2_texture = sdl2.SDL_CreateTexture(window.sdl2_renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_STATIC, w, h);
        errdefer sdl2.SDL_DestroyTexture(texture.sdl2_texture);
        if (texture.sdl2_texture == null) {
            return SimpleTextureError.sdl_create_error;
        }

        if (sdl2.SDL_UpdateTexture(texture.sdl2_texture, null, pixels, w * 4) != 0) {
            return SimpleTextureError.sdl_create_error;
        }
        return texture;
    }

    pub fn destroy(self: *this) void {
        sdl2.SDL_DestroyTexture(self.sdl2_texture);
    }
};

// todo: IMPLEMENT ANIMATED TEXTURES

pub const FontTexture = struct {
    const this = @This();
    pub const font_width = 6;
    pub const font_height = 12;

    usingnamespace this;

    pub const FontError = error{
        sdl_init_error,
        webp_parse_error,
    };
    pub const FontGlyph = struct {
        index: u8,
        sdl_texture: *sdl2.SDL_Texture,
    };

    allocator: std.mem.Allocator,
    glyphs: std.ArrayList(FontGlyph),

    pub fn init(window: Window, filename: []const u8) !this {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        var font: this = undefined;
        font.allocator = allocator;
        font.glyphs = std.ArrayList(FontGlyph).init();

        const fonts_dir: std.fs.Dir = state.appdata_dir.openDir("fonts", .{});
        defer fonts_dir.close();

        const font_file: std.fs.File = fonts_dir.openDir(filename, .{});
        defer font_file.close();
        const font_file_len: usize = try font_file.getEndPos();

        const buffer: []u8 = font.allocator.alloc(u8, font_file_len);
        defer font.allocator.free(buffer);

        _ = try font_file.readAll(buffer);

        var width: usize = undefined;
        var height: usize = undefined;
        const data: []const u8 = webp.WebPDecodeARGB(buffer, buffer.len, &width, &height) orelse {
            return this.FontError.webp_parse_error;
        };

        const glyphs_num = @divTrunc(width, this.font_width);
        const rows_num = @divTrunc(height, this.font_height);

        for (0..rows_num) |row| {
            for (0..glyphs_num) |glyph| {
                var glyphs_buffer = std.ArrayList(u8).init(font.allocator);
                defer glyphs_buffer.deinit();

                for (0..this.font_height) |y| {
                    for (0..this.font_width) |x| {
                        glyphs_buffer.insert(y + x, data[row * y + glyph * x]);
                    }
                }
                var curr_glyph: this.FontGlyph = undefined;
                curr_glyph.index = row + glyph;
                curr_glyph.sdl_texture = sdl2.SDL_CreateTexture(window.sdl2_renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_STATIC, this.font_width, this.font_height);
                if (curr_glyph.sdl_texture == null) {
                    return this.FontError.sdl_init_error;
                }
                if (sdl2.SDL_UpdateTexture(curr_glyph.sdl_texture, null, glyphs_buffer.items, font_width * 4) != 0) {
                    return this.FontError.sdl_init_error;
                }

                font.glyphs.append(curr_glyph);
            }
        }
    }

    pub fn destroy(self: *this) void {
        for (self.glyphs.items) |item| {
            sdl2.SDL_DestroyTexture(item.sdl_texture);
        }
        self.glyphs.deinit();
    }
};
