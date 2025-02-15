const std = @import("std");
const zap = @import("zap.zig");
const zut = @import("zut");

pub fn Bmp(comptime bpp: u6) type {
    return struct {
        width: usize,
        height: usize,
        pixels: []align(1) Rgb,
        px_len: usize = bytes_per_px,
        byte_width: usize,
        row_width: usize,

        pub const bytes_per_px: usize = bpp / 8;

        pub const Rgb = switch (bpp) {
            1, 4, 8 => union { b: u8, g: u8, r: u8, a: u8 },
            16 => packed struct { b: u5, g: u5, r: u5, a: u1 },
            24 => struct { b: u8 align(1), g: u8 align(1), r: u8 align(1), a: u0 align(1) },
            32 => packed struct { b: u8, g: u8, r: u8, a: u8 },
            else => unreachable,
        };

        pub fn init(width: usize, height: usize, data: []u8) !@This() {
            const byte_width = bytes_per_px * width;
            const row_width: usize = @intCast(zut.mem.aligned(@intCast(byte_width), 4));

            return @This(){
                .width = @intCast(width),
                .height = @intCast(height),
                .pixels = std.mem.bytesAsSlice(Rgb, data),
                .row_width = @intCast(row_width),
                .byte_width = byte_width,
            };
        }

        pub fn write(self: *@This(), writer: anytype, info: ?bmp.InfoHeader, palette: ?[]u8) !void {
            const data_size: u32 = zut.mem.intCast(u32, self.row_width) * zut.mem.intCast(u32, self.height);
            const palette_size = if (bpp > 8) 0 else (@as(u16, 1) << zut.mem.intCast(u4, bpp)) * 4;
            const offset: u32 = @intCast(bmp.FileHeader.len + bmp.InfoHeader.len + palette_size);

            var w = std.io.bufferedWriter(writer);
            try zut.mem.packedWrite(bmp.FileHeader{ .offset = offset, .size = offset + data_size }, &w);
            var info_header = info orelse bmp.InfoHeader{};
            info_header.width = @intCast(self.width);
            info_header.height = @intCast(self.height);
            info_header.size = bmp.InfoHeader.len;
            info_header.size_image = @intCast(data_size);
            info_header.bit_count = bpp;
            try zut.mem.packedWrite(info_header, &w);

            if (palette) |p| {
                _ = try w.write(p);
            }

            const data = std.mem.sliceAsBytes(self.pixels);
            for (0..self.height) |y| {
                _ = try w.write(data[y * self.byte_width .. y * self.byte_width + self.byte_width]);
                for (0..self.row_width - self.byte_width) |_| {
                    _ = try w.write(&[_]u8{0});
                }
            }

            try w.flush();
        }
    };
}

pub const bmp = struct {
    pub const FileHeader = struct {
        pub const len = zut.mem.packedSize(FileHeader);

        type: u16 = std.mem.readInt(u16, "BM", .little),
        size: u32,
        reserved: u32 = 0,
        offset: u32,
    };

    pub const InfoHeader = struct {
        pub const len = zut.mem.packedSize(InfoHeader);

        size: u32 = 0,
        width: i32 = 0,
        height: i32 = 0,
        planes: u16 = 1,
        bit_count: u16 = 0,
        compression: u32 = 0,
        size_image: u32 = 0,
        x_pels_per_meter: i32 = 3780,
        y_pels_per_meter: i32 = 3780,
        clr_used: u32 = 0,
        clr_important: u32 = 0,
    };
};
