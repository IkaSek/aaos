const std = @import("std");
/// this is a *GLOBAL* element, it is meant to be a global.
pub var appdata_dir: std.fs.Dir = undefined;

pub inline fn openAppdata(allocator: std.mem.Allocator, program: []const u8) !std.fs.Dir {
    const appdata_dir_path: []u8 = std.fs.getAppDataDir(allocator, program);
    defer allocator.free(appdata_dir_path);

    appdata_dir = try std.fs.openDirAbsolute(appdata_dir_path, .{});
}

pub fn init(allocator: std.mem.Allocator) !void {
    try openAppdata(allocator, "aaos");
}

pub fn destroy() void {
    appdata_dir.close();
}
