const std = @import("std");
const sdl2 = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_video.h");
});
const this = @This();

const Window = @import("Window.zig");

window: *Window,

pub fn init(window: *Window) !this {
    var menu: this = undefined;
    menu.window = window;
}

pub fn eventLoop() void {}
