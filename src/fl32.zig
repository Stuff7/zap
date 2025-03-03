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

    pub fn read(allocator: Allocator, reader: anytype) !Fl32 {
        var header: [4]u8 = undefined;
        var r = std.io.bufferedReader(reader);
        _ = try r.read(&header);
        try zut.dbg.rtAssert(std.mem.eql(u8, &header, header_id), error.InvalidFl32);

        var self = try zut.mem.packedRead(Fl32, &r, "data");
        self.data = try allocator.alloc(f32, self.width * self.height * self.num_channels);

        const bytes_read = try r.read(std.mem.sliceAsBytes(self.data));

        if (bytes_read < self.data.len * @sizeOf(f32)) {
            _ = try r.read(std.mem.sliceAsBytes(self.data)[bytes_read..]); // flush
        }

        return self;
    }

    pub fn write(self: Fl32, writer: anytype) !void {
        var w = std.io.bufferedWriter(writer);
        _ = try w.write(header_id);
        try zut.mem.packedWrite(self, &w);
        try w.flush();
    }
};
