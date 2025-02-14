const std = @import("std");
const gm = @import("zap.zig");
const zut = @import("zut");

const m = std.math;
const Allocator = std.mem.Allocator;

/// ## FL32 file Format
/// - 4-byte ASCII header: `"FL32"`
/// - 4-byte `u32`: `height` (image height in pixels)
/// - 4-byte `u32`: `width` (image width in pixels)
/// - 4-byte `u32`: `num_channels` (number of floating-point values per pixel)
/// - `f32` array: `data` (distance field values)
pub const Fl32 = struct {
    height: u32,
    width: u32,
    num_channels: u32 = 1,
    data: []f32,

    const header_id = "FL32";

    pub fn readFile(allocator: Allocator, path: []const u8) !Fl32 {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var header: [4]u8 = undefined;
        _ = try file.read(&header);
        try zut.dbg.rtAssert(std.mem.eql(u8, &header, header_id), error.InvalidFl32);

        var sdf = try zut.mem.packedRead(Fl32, file, "data");

        const meta = try file.stat();
        sdf.data = std.mem.bytesAsSlice(f32, try file.readToEndAllocOptions(
            allocator,
            meta.size,
            meta.size,
            @alignOf(f32),
            null,
        ));

        return sdf;
    }

    pub fn writeFile(self: Fl32, filename: []const u8) !void {
        const file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        _ = try file.write(header_id);
        try zut.mem.packedWrite(self, file);
    }
};
