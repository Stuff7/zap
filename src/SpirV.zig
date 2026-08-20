const std = @import("std");
const zut = @import("zut");
const mem = zut.mem;

const Allocator = std.mem.Allocator;

pub const types = @import("spirv-types.zig");

pub const SpirV = @This();

version: u32,
generator: u32,
bound: u32,
schema: u32,
arena: std.heap.ArenaAllocator,
reader: *std.Io.Reader,

const header_id = 0x07230203;

pub fn read(allocator: Allocator, r: *std.Io.Reader) !SpirV {
    var header: u32 = 0;

    try r.readSliceAll(std.mem.asBytes(&header));

    if (header != header_id) {
        return error.InvalidSpirV;
    }

    var self = try mem.packedRead(SpirV, r, "arena");

    self.arena = std.heap.ArenaAllocator.init(allocator);
    self.reader = r;

    return self;
}

pub fn nextInstruction(self: *SpirV) !?Instruction {
    return Instruction.read(self.arena.allocator(), self.reader);
}

pub fn deinit(self: SpirV) void {
    self.arena.deinit();
}

pub const Instruction = union(enum(u16)) {
    source: types.Source = 3,
    name: types.Name = 5,
    member_name: types.MemberName = 6,
    ext_inst_import: types.ExtInstImport = 11,
    ext_inst: types.ExtInst = 12,
    memory_model: types.MemoryModel = 14,
    entry_point: types.EntryPoint = 15,
    execution_mode: types.ExecutionMode = 16,
    capability: types.Capability = 17,
    type: types.Type,
    type_pointer: types.TypePointer = 32,
    constant: types.Constant = 43,
    constant_composite: types.ConstantComposite = 44,
    spec_constant: types.SpecConstant = 50,
    function: types.Function = 54,
    function_end: void = 56,
    variable: types.Variable = 59,
    load: types.Load = 61,
    store: types.Store = 62,
    access_chain: types.AccessChain = 65,
    decorate: types.Decorate = 71,
    member_decorate: types.MemberDecorate = 72,
    vector_shuffle: types.VectorShuffle = 79,
    composite_construct: types.CompositeConstruct = 80,
    composite_extract: types.CompositeExtract = 81,
    image_sample_implicit_lod: types.ImageSampleImplicitLod = 87,
    fnegate: types.FNegate = 127,
    fadd: types.FAdd = 129,
    fmul: types.FMul = 133,
    vector_times_scalar: types.VectorTimesScalar = 142,
    matrix_times_vector: types.MatrixTimesVector = 145,
    matrix_times_matrix: types.MatrixTimesMatrix = 146,
    fwidth: types.FWidth = 209,
    label: types.Label = 248,
    op_return: void = 253,

    pub fn read(allocator: Allocator, reader: *std.Io.Reader) !?Instruction {
        var code: types.Op = undefined;

        if (try reader.readSliceShort(std.mem.asBytes(&code)) == 0) {
            return null;
        }

        var word_count: u16 = undefined;
        try reader.readSliceAll(std.mem.asBytes(&word_count));
        word_count -|= 1;

        var buf: [256]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);

        const words = try fba.allocator().alloc(u8, word_count * 4);
        try reader.readSliceAll(words);
        var r = std.Io.Reader.fixed(words);

        return switch (code) {
            .source => {
                var s = try mem.packedRead(types.Source, &r, "file_id");
                s.file_id = readAsEndian(u32, &r, .little) catch null;
                s.source = readString(allocator, &r) catch null;
                return .{ .source = s };
            },
            .name => {
                var s = try mem.packedRead(types.Name, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .name = s };
            },
            .member_name => {
                var s = try mem.packedRead(types.MemberName, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .member_name = s };
            },
            .ext_inst_import => {
                var s = try mem.packedRead(types.ExtInstImport, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .ext_inst_import = s };
            },
            .ext_inst => {
                var s = try mem.packedRead(types.ExtInst, &r, "operands");
                s.operands = try readToEnd(u32, allocator, &r);
                return .{ .ext_inst = s };
            },
            .memory_model => .{ .memory_model = try mem.packedRead(types.MemoryModel, &r, null) },
            .entry_point => {
                var s = try mem.packedRead(types.EntryPoint, &r, "name");
                s.name = try readString(allocator, &r);
                s.interface = try readToEnd(u32, allocator, &r);
                return .{ .entry_point = s };
            },
            .execution_mode => {
                var s = try mem.packedRead(types.ExecutionMode, &r, "operands");
                s.operands = try readToEnd(u32, allocator, &r);
                return .{ .execution_mode = s };
            },
            .capability => .{ .capability = std.mem.bytesToValue(types.Capability, words) },
            .type_void => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .void } },
            .type_bool => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .bool } },
            .type_int => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .{ .int = try mem.packedRead(types.Type.Int, &r, null) } } },
            .type_vector => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .{ .vector = try mem.packedRead(types.Type.Vector, &r, null) } } },
            .type_matrix => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .{ .matrix = try mem.packedRead(types.Type.Matrix, &r, null) } } },
            .type_sampled_image => .{
                .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .{ .sampled_image = try mem.packedRead(types.Type.SampledImage, &r, null) } },
            },
            .type_array => .{ .type = .{ .result_id = try readAsEndian(u32, &r, .little), .info = .{ .array = try mem.packedRead(types.Type.Array, &r, null) } } },
            .type_float, .type_image, .type_struct, .type_function => {
                var t: types.Type = undefined;
                t.result_id = try readAsEndian(u32, &r, .little);

                t.info = ret: switch (code) {
                    .type_float => {
                        var s = try mem.packedRead(types.Type.Float, &r, "encoding");
                        s.encoding = readAsEndian(u32, &r, .little) catch null;
                        break :ret .{ .float = s };
                    },
                    .type_image => {
                        var s = try mem.packedRead(types.Type.Image, &r, "access_qualifier");
                        r.readSliceAll(std.mem.asBytes(&s.access_qualifier)) catch {
                            s.access_qualifier = null;
                        };
                        break :ret .{ .image = s };
                    },
                    .type_struct => {
                        var s = try mem.packedRead(types.Type.Struct, &r, "member_ids");
                        s.member_ids = try readToEnd(u32, allocator, &r);
                        break :ret .{ .@"struct" = s };
                    },
                    .type_function => {
                        var s = try mem.packedRead(types.Type.Function, &r, "parameter_ids");
                        s.parameter_ids = try readToEnd(u32, allocator, &r);
                        break :ret .{ .function = s };
                    },
                    else => unreachable,
                };

                return .{ .type = t };
            },
            .type_pointer => .{ .type_pointer = try mem.packedRead(types.TypePointer, &r, null) },
            .constant => {
                var s = try mem.packedRead(types.Constant, &r, "value");
                s.value = try readToEnd(u32, allocator, &r);
                return .{ .constant = s };
            },
            .constant_composite => {
                var s = try mem.packedRead(types.ConstantComposite, &r, "constituent_ids");
                s.constituent_ids = try readToEnd(u32, allocator, &r);
                return .{ .constant_composite = s };
            },
            .spec_constant => {
                var s = try mem.packedRead(types.SpecConstant, &r, "value");
                s.value = try readToEnd(u32, allocator, &r);
                return .{ .spec_constant = s };
            },
            .function => .{ .function = try mem.packedRead(types.Function, &r, null) },
            .function_end => .function_end,
            .variable => {
                var s = try mem.packedRead(types.Variable, &r, "initializer_id");
                s.initializer_id = readAsEndian(u32, &r, .little) catch null;
                return .{ .variable = s };
            },
            .load => {
                var s = try mem.packedRead(types.Load, &r, "memory_operands");
                s.memory_operands = try readToEnd(u32, allocator, &r);
                return .{ .load = s };
            },
            .store => {
                var s = try mem.packedRead(types.Store, &r, "memory_operands");
                s.memory_operands = try readToEnd(u32, allocator, &r);
                return .{ .store = s };
            },
            .access_chain => {
                var s = try mem.packedRead(types.AccessChain, &r, "index_ids");
                s.index_ids = try readToEnd(u32, allocator, &r);
                return .{ .access_chain = s };
            },
            .decorate => {
                var s = try mem.packedRead(types.Decorate, &r, "operands");
                s.operands = readToEnd(u32, allocator, &r) catch &[0]u32{};
                return .{ .decorate = s };
            },
            .member_decorate => {
                var s = try mem.packedRead(types.MemberDecorate, &r, "operands");
                s.operands = readToEnd(u32, allocator, &r) catch &[0]u32{};
                return .{ .member_decorate = s };
            },
            .vector_shuffle => {
                var s = try mem.packedRead(types.VectorShuffle, &r, "components");
                s.components = readToEnd(u32, allocator, &r) catch &[0]u32{};
                return .{ .vector_shuffle = s };
            },
            .composite_construct => {
                var s = try mem.packedRead(types.CompositeConstruct, &r, "constituent_ids");
                s.constituent_ids = try readToEnd(u32, allocator, &r);
                return .{ .composite_construct = s };
            },
            .composite_extract => {
                var s = try mem.packedRead(types.CompositeExtract, &r, "index_ids");
                s.index_ids = try readToEnd(u32, allocator, &r);
                return .{ .composite_extract = s };
            },
            .image_sample_implicit_lod => {
                var s = try mem.packedRead(types.ImageSampleImplicitLod, &r, "image_operands");
                s.image_operands = readToEnd(types.ImageOperands, allocator, &r) catch &[0]types.ImageOperands{};
                return .{ .image_sample_implicit_lod = s };
            },
            .fnegate => .{ .fnegate = try mem.packedRead(types.FNegate, &r, null) },
            .fadd => .{ .fadd = try mem.packedRead(types.FAdd, &r, null) },
            .fmul => .{ .fmul = try mem.packedRead(types.FMul, &r, null) },
            .vector_times_scalar => .{ .vector_times_scalar = try mem.packedRead(types.VectorTimesScalar, &r, null) },
            .matrix_times_vector => .{ .matrix_times_vector = try mem.packedRead(types.MatrixTimesVector, &r, null) },
            .matrix_times_matrix => .{ .matrix_times_matrix = try mem.packedRead(types.MatrixTimesMatrix, &r, null) },
            .fwidth => .{ .fwidth = try mem.packedRead(types.FWidth, &r, null) },
            .label => .{ .label = try mem.packedRead(types.Label, &r, null) },
            .op_return => .op_return,
            else => |name| {
                std.debug.print("TODO: Hit unsupported instruction at {d:.2}% \n\tInstruction: {}\n\tCode: {}\n\tWord count: {d}", .{
                    100 * zut.mem.asFloat(f32, reader.seek) / zut.mem.asFloat(f32, reader.end),
                    name,
                    code,
                    word_count,
                });
                return null;
            },
        };
    }
};

fn readString(allocator: Allocator, r: *std.Io.Reader) ![]u8 {
    const str = try r.takeDelimiterExclusive(0);

    if (str.len == 0) {
        return &[0]u8{};
    }

    return allocator.dupe(u8, str);
}

fn readToEnd(T: type, allocator: Allocator, r: *std.Io.Reader) ![]T {
    const len = r.bufferedLen();

    if (len == 0) {
        return &[0]T{};
    }

    const dest = try allocator.alloc(T, len / @sizeOf(T));
    try r.readSliceAll(std.mem.sliceAsBytes(dest));

    return dest;
}

pub fn readAsEndian(T: type, r: *std.Io.Reader, endian: std.builtin.Endian) !T {
    var v: [1]T = undefined;
    return if (r.readSliceEndian(T, &v, endian)) v[0] else |e| return e;
}
