const std = @import("std");
const zap = @import("zap");
const zut = @import("zut");
const dump = zut.dbg.dump;

pub fn main(proc: std.process.Init) !void {
    const allocator = proc.gpa;

    const args = try proc.minimal.args.toSlice(proc.arena.allocator());

    if (args.len < 2) {
        std.debug.print(
            \\Usage {s}
            \\  fl32   Test fl32 format
            \\  bmp    Write a test bmp file
            \\  spirv  Read a Spir-V file
        , .{args[0]});
        return;
    }

    if (std.mem.eql(u8, args[1], "fl32")) {
        if (args.len < 3) {
            std.debug.print(
                \\Usage {s}
                \\  <file>   FL32 file save location
            , .{args[1]});
            return;
        }

        const file = try std.Io.Dir.cwd().createFile(proc.io, args[2], .{ .read = true });
        defer file.close(proc.io);
        var wbuf: [256]u8 = undefined;
        var writer = file.writer(proc.io, &wbuf);

        const fl32 = zap.Fl32{
            .header = .{ .width = 4, .height = 2 },
            .data = @constCast(&[_]f32{ 1, 2, 3, 4, 5, 6, 7, 8 }),
        };
        dump(fl32);
        try fl32.write(&writer.interface);

        var rbuf: [256]u8 = undefined;
        var reader = file.reader(proc.io, &rbuf);
        const fl32r = try zap.Fl32.read(allocator, &reader.interface);
        defer allocator.free(fl32r.data);
        dump(fl32r);
    } else if (std.mem.eql(u8, args[1], "bmp")) {
        if (args.len < 3) {
            std.debug.print(
                \\Usage {s}
                \\  <file>   BMP file save location"
            , .{args[1]});
            return;
        }

        const width = 16;
        const height = 16;
        var buffer: [width * height * zap.bmp.Bmp(16).bytes_per_px]u8 = @splat(0);
        var bmp = try zap.bmp.Bmp(16).init(width, height, &buffer);
        dump(bmp);

        for (0..bmp.width - 4) |i| {
            const off_l = 2;
            const off_r = bmp.width - 3;

            bmp.pixels[2 * bmp.width + 2 + i].g = 31;
            bmp.pixels[off_r * bmp.width + off_l + i].g = 31;
            bmp.pixels[(i + off_l) * bmp.width + off_l].g = 31;
            bmp.pixels[(i + off_l) * bmp.width + off_r].g = 31;
        }

        const file = try std.Io.Dir.cwd().createFile(proc.io, args[2], .{});
        defer file.close(proc.io);
        var wbuf: [256]u8 = undefined;
        var writer = file.writer(proc.io, &wbuf);
        try bmp.write(&writer.interface, null, null);
    } else if (std.mem.eql(u8, args[1], "spirv")) {
        if (args.len < 3) {
            std.debug.print(
                \\Usage {s}
                \\  <file> [query] [options]    SPIR-V file path + optional query
                \\  --------QUERIES---------    
                \\  name <text>                 Find SPIR-V instruction id by it's variable or type name
                \\  type <id>                   Find SPIR-V type by it's id
                \\  type-ptr <id>               Find SPIR-V type pointer by it's id
                \\  member <id|text>            Find SPIR-V member info by it's id or member name
            , .{args[1]});
            return;
        }

        const file = try std.Io.Dir.cwd().openFile(proc.io, args[2], .{});
        defer file.close(proc.io);

        var rbuf: [256]u8 = undefined;
        var reader = file.reader(proc.io, &rbuf);
        var spirv = try zap.SpirV.read(allocator, &reader.interface);
        defer spirv.deinit();

        if (args.len < 4) {
            dump(spirv);

            while (try spirv.nextInstruction()) |inst| {
                dump(inst);
            }

            return;
        }

        var instruction_list = std.ArrayList(zap.SpirV.Instruction).empty;

        while (try spirv.nextInstruction()) |inst| {
            try instruction_list.append(allocator, inst);
        }

        const instructions = try instruction_list.toOwnedSlice(allocator);
        defer allocator.free(instructions);

        const query_param = if (args.len > 4) args[4] else null;

        if (std.mem.eql(u8, args[3], "name")) {
            for (instructions) |inst| {
                if (inst == .name and (query_param == null or std.mem.eql(u8, inst.name.name, query_param.?))) {
                    dump(inst.name);
                }
            }
        } else if (std.mem.eql(u8, args[3], "var")) {
            const id = if (query_param) |q| try std.fmt.parseInt(u32, q, 10) else null;

            for (instructions) |inst| {
                if (inst == .variable and (id == null or inst.variable.result_id == id)) {
                    dump(inst.variable);
                }
            }
        } else if (std.mem.eql(u8, args[3], "type")) {
            const id = if (query_param) |q| try std.fmt.parseInt(u32, q, 10) else null;

            for (instructions) |inst| {
                if (inst == .type and (id == null or inst.type.result_id == id)) {
                    dump(inst.type);
                }
            }
        } else if (std.mem.eql(u8, args[3], "type-ptr")) {
            const id = if (query_param) |q| try std.fmt.parseInt(u32, q, 10) else null;

            for (instructions) |inst| {
                if (inst == .type_pointer and (id == null or inst.type_pointer.result_id == id)) {
                    dump(inst.type_pointer);
                }
            }
        } else if (std.mem.eql(u8, args[3], "member")) {
            const id = if (query_param) |q| std.fmt.parseInt(u32, q, 10) catch null else null;
            const name = if (id == null) query_param else null;

            for (instructions) |inst| {
                if (name != null and inst == .member_name and std.mem.eql(u8, inst.member_name.name, name.?)) {
                    dump(inst.member_name);
                } else if (id != null and inst == .member_decorate and inst.member_decorate.struct_type_id == id) {
                    dump(inst.member_decorate);
                } else if (id == null and name == null and (inst == .member_name or inst == .member_decorate)) {
                    dump(inst);
                }
            }
        }
    }
}
