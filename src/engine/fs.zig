const std = @import("std");

fn bsStrEql(_: void, key: []const u8, value: []const u8) std.math.Order {
    var result: std.math.Order = .eq;
    if (value.len < key.len) {
        result = .lt;
        key = key[0..value.len];
    } else if (value.len > key.len) {
        result = .gt;
        value = value[0..key.len];
    }

    for (key, value) |k, v| {
        const order = std.math.order(k, v);
        if (order != .eq) {
            return order;
        }
    }
    return result;
}

pub const XDG = enum {
    XDG_DATA_HOME,
    XDG_CACHE_HOME,
    XDG_CONFIG_HOME,
};

pub fn getXdg(xdg: XDG) []const u8 {
    switch (xdg) {
        .XDG_DATA_HOME => return std.posix.getenv("XDG_DATA_HOME") orelse "~/.local/share",
        .XDG_CACHE_HOME => return std.posix.getenv("XDG_CACHE_HOME") orelse "~/.cache",
        .XDG_CONFIG_HOME => return std.posix.getenv("XDG_CONFIG_HOME") orelse "~/.config",
    }
}

pub const dir_mgmt = struct {
    pub const TexturesDirMgrError = error{
        asset_not_found,
    };
    pub const TexturesDirMgr = struct {
        const this = @This();
        /// directories should be:
        ///   ./textures (dev)
        ///   $XDG_DATA_HOME/aaos/textures
        ///   ~/.local/share/aaos/textures
        ///   other user configured textures dirs
        directories: []std.fs.Dir,
        /// allocator context
        allocator: std.mem.Allocator,

        /// returns a readonly std.fs.File
        pub fn findFile(self: *this, name: []const u8) !std.fs.File {
            for (self.directories) |dir| {
                var fnames: [][]const u8 = self.allocator.alloc(u8, 0);
                defer self.allocator.free(fnames);
                const dir_iterator: std.fs.Dir.Iterator = dir.iterate();
                while (try dir_iterator.next() != null) |iterator_name| {
                    fnames = try self.allocator.realloc(fnames, fnames.len + 1);
                    fnames[fnames.len - 1] = iterator_name;
                }

                if (std.sort.binarySearch([]const u8, name, fnames, {}, bsStrEql) == null) {
                    continue;
                }

                return dir.openFile(name, .{});
            }
            return TexturesDirMgrError.asset_not_found;
        }

        pub fn destroy(self: *this) void {
            for (self.directories) |dir| {
                dir.close();
            }
            self.allocator.destroy(self.directories);
        }
    };

    pub fn texuresDirMgr(custom_dirs: ?[]std.fs.Dir) !TexturesDirMgr {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var txtdirmgr: TexturesDirMgr = undefined;
        txtdirmgr.allocator = allocator;
        txtdirmgr.directories = allocator.alloc(std.fs.Dir, 3);
        txtdirmgr.directories[0] = std.fs.cwd();
        txtdirmgr.directories[1] = getXdg(.XDG_DATA_HOME) ++ "/aaos/textures";
        if (custom_dirs != null) {
            txtdirmgr.directories = allocator.realloc(txtdirmgr.directories, txtdirmgr.directories.len + custom_dirs.?.len);
            for (custom_dirs.?, custom_dirs.?.len) |dir, i| {
                txtdirmgr.directories[i + 1] = dir;
            }
        }
        return txtdirmgr;
    }
};
