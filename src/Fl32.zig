const std = @import("std");

const Allocator = std.mem.Allocator;

/// ## FL32 file Format
/// - 4-byte ASCII header: `"FL32"`
/// - 4-byte `u32`: `height` (image height in pixels)
/// - 4-byte `u32`: `width` (image width in pixels)
/// - 4-byte `u32`: `num_channels` (number of floating-point values per pixel)
/// - `f32` array: `data` (distance field values)
const Fl32 = @This();

header: Header,
data: []f32,

const Header = packed struct {
    height: u32,
    width: u32,
    num_channels: u32 = 1,
    const id = std.mem.readInt(u32, "FL32", .little);
};

pub fn read(allocator: Allocator, r: *std.Io.Reader) !Fl32 {
    if (try r.takeInt(u32, .little) != Header.id) return error.InvalidFl32;

    const header = try r.takeStruct(Header, .little);
    const data = try allocator.alloc(f32, header.width * header.height * header.num_channels);

    const bytes_read = try r.readSliceShort(std.mem.sliceAsBytes(data));

    if (bytes_read < data.len * @sizeOf(f32)) {
        try r.readSliceAll(std.mem.sliceAsBytes(data)[bytes_read..]);
    }

    return .{ .header = header, .data = data };
}

pub fn write(self: Fl32, w: *std.Io.Writer) !void {
    _ = try w.writeInt(u32, Header.id, .little);
    try w.writeStruct(self.header, .little);
    try w.writeAll(std.mem.sliceAsBytes(self.data));
    try w.flush();
}
