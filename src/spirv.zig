const std = @import("std");
const zut = @import("zut");
const spirv = @import("spirv-types.zig");

const mem = zut.mem;
const BufStream = @import("bufstream.zig").BufStream;
const Allocator = std.mem.Allocator;

pub const SpirV = @This();

version: u32,
generator: u32,
bound: u32,
schema: u32,

const header_id = 0x07230203;

pub fn read(reader: anytype) !SpirV {
    var r = std.io.bufferedReader(reader);
    var header: u32 = 0;

    _ = try r.read(std.mem.asBytes(&header));

    if (header != header_id) {
        return error.InvalidSpirV;
    }

    const self = try mem.packedRead(SpirV, &r, null);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    while (try Instruction.read(allocator, &r)) |i| {
        zut.dbg.dump(i);
    }

    return self;
}

pub const Instruction = union(enum(u16)) {
    source: spirv.Source = 3,
    name: spirv.Name = 5,
    member_name: spirv.MemberName = 6,
    ext_inst_import: spirv.ExtInstImport = 11,
    memory_model: spirv.MemoryModel = 14,
    entry_point: spirv.EntryPoint = 15,
    capability: spirv.Capability = 17,
    type_void: spirv.TypeVoid = 19,
    type_int: spirv.TypeInt = 21,
    type_float: spirv.TypeFloat = 22,
    type_vector: spirv.TypeVector = 23,
    type_matrix: spirv.TypeMatrix = 24,
    type_struct: spirv.TypeStruct = 30,
    type_pointer: spirv.TypePointer = 32,
    type_function: spirv.TypeFunction = 33,
    constant: spirv.Constant = 43,
    function: spirv.Function = 54,
    variable: spirv.Variable = 59,
    decorate: spirv.Decorate = 71,
    member_decorate: spirv.MemberDecorate = 72,
    label: spirv.Label = 248,

    pub fn read(allocator: Allocator, reader: anytype) !?Instruction {
        var code: spirv.Op = undefined;
        _ = try reader.read(std.mem.asBytes(&code));

        var word_count: u16 = undefined;
        _ = try reader.read(std.mem.asBytes(&word_count));
        word_count -|= 1;
        zut.dbg.print("{} {d}", .{ code, word_count });

        var buf: [64]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);

        const words = try fba.allocator().alloc(u8, word_count * 4);
        _ = try reader.read(words);
        var r = BufStream{ .buf = words };

        return switch (code) {
            .source => {
                var s = try mem.packedRead(spirv.Source, &r, "file_id");
                s.file_id = r.readAs(u32) catch null;
                s.source = readString(allocator, &r) catch null;
                return .{ .source = s };
            },
            .name => {
                var s = try mem.packedRead(spirv.Name, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .name = s };
            },
            .member_name => {
                var s = try mem.packedRead(spirv.MemberName, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .member_name = s };
            },
            .ext_inst_import => {
                var s = try mem.packedRead(spirv.ExtInstImport, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .ext_inst_import = s };
            },
            .memory_model => .{ .memory_model = try mem.packedRead(spirv.MemoryModel, &r, null) },
            .entry_point => {
                var s = try mem.packedRead(spirv.EntryPoint, &r, "name");

                s.name = try readString(allocator, &r);
                s.interface = try readToEnd(u32, allocator, &r);

                return .{ .entry_point = s };
            },
            .capability => .{ .capability = std.mem.bytesToValue(spirv.Capability, words) },
            .type_void => {
                const s = try mem.packedRead(spirv.TypeVoid, &r, null);
                return .{ .type_void = s };
            },
            .type_int => {
                const s = try mem.packedRead(spirv.TypeInt, &r, null);
                return .{ .type_int = s };
            },
            .type_float => {
                var s = try mem.packedRead(spirv.TypeFloat, &r, "encoding");
                s.encoding = r.readAs(u32) catch null;
                return .{ .type_float = s };
            },
            .type_vector => {
                const s = try mem.packedRead(spirv.TypeVector, &r, null);
                return .{ .type_vector = s };
            },
            .type_matrix => return .{ .type_matrix = try mem.packedRead(spirv.TypeMatrix, &r, null) },
            .type_struct => {
                var s = try mem.packedRead(spirv.TypeStruct, &r, "member_ids");
                s.member_ids = try readToEnd(u32, allocator, &r);
                return .{ .type_struct = s };
            },
            .type_pointer => {
                const s = try mem.packedRead(spirv.TypePointer, &r, null);
                return .{ .type_pointer = s };
            },
            .type_function => {
                var s = try mem.packedRead(spirv.TypeFunction, &r, "parameter_ids");
                s.parameter_ids = try readToEnd(u32, allocator, &r);
                return .{ .type_function = s };
            },
            .constant => {
                var s = try mem.packedRead(spirv.Constant, &r, "value");
                s.value = try readToEnd(u32, allocator, &r);
                return .{ .constant = s };
            },
            .function => return .{ .function = try mem.packedRead(spirv.Function, &r, null) },
            .variable => {
                var s = try mem.packedRead(spirv.Variable, &r, "initializer_id");
                s.initializer_id = r.readAs(u32) catch null;
                return .{ .variable = s };
            },
            .decorate => {
                const s = try mem.packedRead(spirv.Decorate, &r, null);
                return .{ .decorate = s };
            },
            .member_decorate => {
                const s = try mem.packedRead(spirv.MemberDecorate, &r, null);
                return .{ .member_decorate = s };
            },
            .label => return .{ .label = try mem.packedRead(spirv.Label, &r, null) },
            else => null,
        };
    }
};

pub fn readString(allocator: Allocator, r: *BufStream) ![]u8 {
    const len = r.readUntilDelimeter(null, 0);

    if (len == 0) {
        return &[0]u8{};
    }

    const dest = try allocator.alloc(u8, len);
    _ = r.readUntilDelimeter(dest, 0);
    r.skip(4) catch {};

    return dest;
}

pub fn readToEnd(T: type, allocator: Allocator, r: *BufStream) ![]T {
    const len = r.readUntilDelimeter(null, 0);

    if (len == 0) {
        return &[0]T{};
    }

    const dest = try allocator.alloc(T, r.readToEnd(null) / @sizeOf(T));
    _ = r.readToEnd(std.mem.sliceAsBytes(dest));

    return dest;
}
