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
const Fl32 = @This();

height: u32,
width: u32,
num_channels: u32 = 1,
data: []f32,

const header_id = "FL32";

pub fn read(allocator: Allocator, r: *std.Io.Reader) !Fl32 {
    var header: [4]u8 = undefined;
    try r.readSliceAll(&header);

    if (std.mem.eql(u8, &header, header_id)) return error.InvalidFl32;

    var self = try zut.mem.packedRead(Fl32, r, "data");
    self.data = try allocator.alloc(f32, self.width * self.height * self.num_channels);

    const bytes_read = try r.readSliceShort(std.mem.sliceAsBytes(self.data));

    if (bytes_read < self.data.len * @sizeOf(f32)) {
        try r.readSliceAll(std.mem.sliceAsBytes(self.data)[bytes_read..]);
    }

    return self;
}

pub fn write(self: Fl32, w: *std.Io.Writer) !void {
    _ = try w.write(header_id);
    try zut.mem.packedWrite(self, w);
    try w.flush();
}
