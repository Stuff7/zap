const std = @import("std");
const zap = @import("zap");
const zut = @import("zut");

const dbg = zut.dbg;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        // zig fmt: off
        zut.dbg.usage(args[0], .{
            "fl32", "Test fl32 format",
            "bmp" , "Write a test bmp file",
            "spirv" , "Read a Spir-V file",
        });
        // zig fmt: on
        return;
    }

    if (std.mem.eql(u8, args[1], "fl32")) {
        if (args.len < 3) {
            zut.dbg.usage(args[1], .{ "<file>", "FL32 file save location" });
            return;
        }

        const file = try std.fs.cwd().openFile(args[2], .{});
        defer file.close();

        const fl32 = zap.Fl32{
            .width = 4,
            .height = 2,
            .data = @constCast(&[_]f32{ 1, 2, 3, 4, 5, 6, 7, 8 }),
        };
        zut.dbg.dump(fl32);
        try fl32.write(file.writer());

        const fl32r = try zap.Fl32.read(allocator, file.reader());
        defer allocator.free(fl32r.data);
        zut.dbg.dump(fl32r);
    } else if (std.mem.eql(u8, args[1], "bmp")) {
        if (args.len < 3) {
            zut.dbg.usage(args[1], .{ "<file>", "BMP file save location" });
            return;
        }

        const width = 16;
        const height = 16;
        var buffer = [_]u8{0} ** (width * height * zap.Bmp(16).bytes_per_px);
        var bmp = try zap.Bmp(16).init(width, height, &buffer);
        zut.dbg.dump(bmp);

        for (0..bmp.width - 4) |i| {
            const off_l = 2;
            const off_r = bmp.width - 3;

            bmp.pixels[2 * bmp.width + 2 + i].g = 31;
            bmp.pixels[off_r * bmp.width + off_l + i].g = 31;
            bmp.pixels[(i + off_l) * bmp.width + off_l].g = 31;
            bmp.pixels[(i + off_l) * bmp.width + off_r].g = 31;
        }

        const file = try std.fs.cwd().createFile(args[2], .{});
        defer file.close();
        try bmp.write(file.writer(), null, null);
    } else if (std.mem.eql(u8, args[1], "spirv")) {
        if (args.len < 3) {
            zut.dbg.usage(args[1], .{ "<file>", "Spir-V file path" });
            return;
        }

        const file = try std.fs.cwd().openFile(args[2], .{});
        defer file.close();

        var spirv = try zap.SpirV.read(allocator, file.reader());
        defer spirv.deinit();

        zut.dbg.dump(spirv);

        while (try spirv.nextInstruction()) |inst| {
            zut.dbg.dump(inst);
        }
    }
}
