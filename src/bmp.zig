const std = @import("std");
const zap = @import("zap.zig");
const zut = @import("zut");

pub fn Bmp(comptime bpp: u6) type {
    return struct {
        width: usize,
        height: usize,
        px_len: usize = bytes_per_px,
        byte_width: usize,
        row_width: usize,
        file: std.fs.File,
        writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

        pub const bytes_per_px = bpp / 8;

        pub const Rgb = switch (bpp) {
            1, 4, 8 => union { b: u8, g: u8, r: u8, a: u8 },
            16 => packed struct { b: u5, g: u5, r: u5, a: u1 },
            24 => struct { b: u8 align(1), g: u8 align(1), r: u8 align(1), a: u0 align(1) },
            32 => packed struct { b: u8, g: u8, r: u8, a: u8 },
            else => unreachable,
        };

        pub fn init(info: bmp.InfoHeader, filename: []const u8) !@This() {
            const byte_width: usize = bytes_per_px * zut.mem.intCast(usize, info.width);
            const row_width: usize = @intCast(zut.mem.aligned(@intCast(byte_width), 4));
            const data_size: u32 = zut.mem.intCast(u32, row_width) * zut.mem.intCast(u32, info.height);
            const palette_size = if (bpp > 8) 0 else (@as(u16, 1) << zut.mem.intCast(u4, bpp)) * 4;
            const offset: u32 = @intCast(bmp.FileHeader.len + bmp.InfoHeader.len + palette_size);

            const file = try std.fs.cwd().createFile(filename, .{});
            var w = std.io.bufferedWriter(file.writer());

            try zut.mem.packedWrite(bmp.FileHeader{ .offset = offset, .size = offset + data_size }, &w);
            var info_header = info;
            info_header.size = bmp.InfoHeader.len;
            info_header.size_image = @intCast(data_size);
            info_header.bit_count = bpp;
            try zut.mem.packedWrite(info_header, &w);

            return @This(){
                .width = @intCast(info.width),
                .height = @intCast(info.height),
                .row_width = @intCast(row_width),
                .byte_width = byte_width,
                .file = file,
                .writer = w,
            };
        }

        pub fn pixels(_: @This(), buffer: []u8) []align(1) Rgb {
            return std.mem.bytesAsSlice(Rgb, buffer);
        }

        pub fn px(_: @This(), buffer: []u8, i: usize) *align(1) if (bytes_per_px < 2) u8 else Rgb {
            comptime if (bytes_per_px < 2) {
                return buffer[i];
            };
            return std.mem.bytesAsValue(Rgb, buffer[i .. i + bytes_per_px]);
        }

        pub fn writeData(self: *@This(), data: []u8) !void {
            defer self.file.close();
            for (0..self.height) |y| {
                _ = try self.writer.write(data[y * self.byte_width .. y * self.byte_width + self.byte_width]);
                for (0..self.row_width - self.byte_width) |_| {
                    _ = try self.writer.write(&[_]u8{0});
                }
            }

            try self.writer.flush();
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
        width: i32,
        height: i32,
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
