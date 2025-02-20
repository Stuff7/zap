const std = @import("std");
const zut = @import("zut");

const mem = zut.mem;
const BufStream = @import("bufstream.zig").BufStream;
const Allocator = std.mem.Allocator;

pub usingnamespace @import("spirv-types.zig");

pub const SpirV = @This();

version: u32,
generator: u32,
bound: u32,
schema: u32,
arena: std.heap.ArenaAllocator,
reader: std.io.BufferedReader(4096, std.fs.File.Reader),

const header_id = 0x07230203;

pub fn read(allocator: Allocator, reader: anytype) !SpirV {
    var r = std.io.bufferedReader(reader);
    var header: u32 = 0;

    _ = try r.read(std.mem.asBytes(&header));

    if (header != header_id) {
        return error.InvalidSpirV;
    }

    var self = try mem.packedRead(SpirV, &r, "arena");

    self.arena = std.heap.ArenaAllocator.init(allocator);
    self.reader = r;

    return self;
}

pub fn deinit(self: SpirV) void {
    self.arena.deinit();
}

pub const Instruction = union(enum(u16)) {
    source: SpirV.Source = 3,
    name: SpirV.Name = 5,
    member_name: SpirV.MemberName = 6,
    ext_inst_import: SpirV.ExtInstImport = 11,
    ext_inst: SpirV.ExtInst = 12,
    memory_model: SpirV.MemoryModel = 14,
    entry_point: SpirV.EntryPoint = 15,
    execution_mode: SpirV.ExecutionMode = 16,
    capability: SpirV.Capability = 17,
    type: SpirV.Type,
    type_pointer: SpirV.TypePointer = 32,
    constant: SpirV.Constant = 43,
    constant_composite: SpirV.ConstantComposite = 44,
    spec_constant: SpirV.SpecConstant = 50,
    function: SpirV.Function = 54,
    function_end: void = 56,
    variable: SpirV.Variable = 59,
    load: SpirV.Load = 61,
    store: SpirV.Store = 62,
    access_chain: SpirV.AccessChain = 65,
    decorate: SpirV.Decorate = 71,
    member_decorate: SpirV.MemberDecorate = 72,
    composite_construct: SpirV.CompositeConstruct = 80,
    composite_extract: SpirV.CompositeExtract = 81,
    image_sample_implicit_lod: SpirV.ImageSampleImplicitLod = 87,
    fnegate: SpirV.FNegate = 127,
    fadd: SpirV.FAdd = 129,
    fmul: SpirV.FMul = 133,
    matrix_times_vector: SpirV.MatrixTimesVector = 145,
    matrix_times_matrix: SpirV.MatrixTimesMatrix = 146,
    fwidth: SpirV.FWidth = 209,
    label: SpirV.Label = 248,
    op_return: void = 253,

    pub fn read(allocator: Allocator, reader: anytype) !?Instruction {
        var code: SpirV.Op = undefined;

        if (try reader.read(std.mem.asBytes(&code)) == 0) {
            return null;
        }

        var word_count: u16 = undefined;
        _ = try reader.read(std.mem.asBytes(&word_count));
        word_count -|= 1;

        var buf: [256]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);

        const words = try fba.allocator().alloc(u8, word_count * 4);
        _ = try reader.read(words);
        var r = BufStream{ .buf = words };

        return switch (code) {
            .source => {
                var s = try mem.packedRead(SpirV.Source, &r, "file_id");
                s.file_id = r.readAsEndian(u32, .little) catch null;
                s.source = readString(allocator, &r) catch null;
                return .{ .source = s };
            },
            .name => {
                var s = try mem.packedRead(SpirV.Name, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .name = s };
            },
            .member_name => {
                var s = try mem.packedRead(SpirV.MemberName, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .member_name = s };
            },
            .ext_inst_import => {
                var s = try mem.packedRead(SpirV.ExtInstImport, &r, "name");
                s.name = try readString(allocator, &r);
                return .{ .ext_inst_import = s };
            },
            .ext_inst => {
                var s = try mem.packedRead(SpirV.ExtInst, &r, "operands");
                s.operands = try readToEnd(u32, allocator, &r);
                return .{ .ext_inst = s };
            },
            .memory_model => .{ .memory_model = try mem.packedRead(SpirV.MemoryModel, &r, null) },
            .entry_point => {
                var s = try mem.packedRead(SpirV.EntryPoint, &r, "name");
                s.name = try readString(allocator, &r);
                s.interface = try readToEnd(u32, allocator, &r);
                return .{ .entry_point = s };
            },
            .execution_mode => {
                var s = try mem.packedRead(SpirV.ExecutionMode, &r, "operands");
                s.operands = try readToEnd(u32, allocator, &r);
                return .{ .execution_mode = s };
            },
            .capability => .{ .capability = std.mem.bytesToValue(SpirV.Capability, words) },
            .type_void => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .void } },
            .type_bool => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .bool } },
            .type_int => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .{ .int = try mem.packedRead(SpirV.TypeInt, &r, null) } } },
            .type_vector => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .{ .vector = try mem.packedRead(SpirV.TypeVector, &r, null) } } },
            .type_matrix => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .{ .matrix = try mem.packedRead(SpirV.TypeMatrix, &r, null) } } },
            .type_sampled_image => .{
                .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .{ .sampled_image = try mem.packedRead(SpirV.TypeSampledImage, &r, null) } },
            },
            .type_array => .{ .type = .{ .result_id = try r.readAsEndian(u32, .little), .info = .{ .array = try mem.packedRead(SpirV.TypeArray, &r, null) } } },
            .type_float, .type_image, .type_struct, .type_function => {
                var t: SpirV.Type = undefined;
                t.result_id = try r.readAsEndian(u32, .little);

                t.info = ret: switch (code) {
                    .type_float => {
                        var s = try mem.packedRead(SpirV.TypeFloat, &r, "encoding");
                        s.encoding = r.readAsEndian(u32, .little) catch null;
                        break :ret .{ .float = s };
                    },
                    .type_image => {
                        var s = try mem.packedRead(SpirV.TypeImage, &r, "access_qualifier");
                        _ = r.read(std.mem.asBytes(&s.access_qualifier)) catch {
                            s.access_qualifier = null;
                        };
                        break :ret .{ .image = s };
                    },
                    .type_struct => {
                        var s = try mem.packedRead(SpirV.TypeStruct, &r, "member_ids");
                        s.member_ids = try readToEnd(u32, allocator, &r);
                        break :ret .{ .@"struct" = s };
                    },
                    .type_function => {
                        var s = try mem.packedRead(SpirV.TypeFunction, &r, "parameter_ids");
                        s.parameter_ids = try readToEnd(u32, allocator, &r);
                        break :ret .{ .function = s };
                    },
                    else => unreachable,
                };

                return .{ .type = t };
            },
            .type_pointer => .{ .type_pointer = try mem.packedRead(SpirV.TypePointer, &r, null) },
            .constant => {
                var s = try mem.packedRead(SpirV.Constant, &r, "value");
                s.value = try readToEnd(u32, allocator, &r);
                return .{ .constant = s };
            },
            .constant_composite => {
                var s = try mem.packedRead(SpirV.ConstantComposite, &r, "constituent_ids");
                s.constituent_ids = try readToEnd(u32, allocator, &r);
                return .{ .constant_composite = s };
            },
            .spec_constant => {
                var s = try mem.packedRead(SpirV.SpecConstant, &r, "value");
                s.value = try readToEnd(u32, allocator, &r);
                return .{ .spec_constant = s };
            },
            .function => .{ .function = try mem.packedRead(SpirV.Function, &r, null) },
            .function_end => .function_end,
            .variable => {
                var s = try mem.packedRead(SpirV.Variable, &r, "initializer_id");
                s.initializer_id = r.readAsEndian(u32, .little) catch null;
                return .{ .variable = s };
            },
            .load => {
                var s = try mem.packedRead(SpirV.Load, &r, "memory_operands");
                s.memory_operands = try readToEnd(u32, allocator, &r);
                return .{ .load = s };
            },
            .store => {
                var s = try mem.packedRead(SpirV.Store, &r, "memory_operands");
                s.memory_operands = try readToEnd(u32, allocator, &r);
                return .{ .store = s };
            },
            .access_chain => {
                var s = try mem.packedRead(SpirV.AccessChain, &r, "index_ids");
                s.index_ids = try readToEnd(u32, allocator, &r);
                return .{ .access_chain = s };
            },
            .decorate => {
                var s = try mem.packedRead(SpirV.Decorate, &r, "operands");
                s.operands = readToEnd(u32, allocator, &r) catch &[0]u32{};
                return .{ .decorate = s };
            },
            .member_decorate => {
                var s = try mem.packedRead(SpirV.MemberDecorate, &r, "operands");
                s.operands = readToEnd(u32, allocator, &r) catch &[0]u32{};
                return .{ .member_decorate = s };
            },
            .composite_construct => {
                var s = try mem.packedRead(SpirV.CompositeConstruct, &r, "constituent_ids");
                s.constituent_ids = try readToEnd(u32, allocator, &r);
                return .{ .composite_construct = s };
            },
            .composite_extract => {
                var s = try mem.packedRead(SpirV.CompositeExtract, &r, "index_ids");
                s.index_ids = try readToEnd(u32, allocator, &r);
                return .{ .composite_extract = s };
            },
            .image_sample_implicit_lod => {
                var s = try mem.packedRead(SpirV.ImageSampleImplicitLod, &r, "image_operands");
                s.image_operands = readToEnd(SpirV.ImageOperands, allocator, &r) catch &[0]SpirV.ImageOperands{};
                return .{ .image_sample_implicit_lod = s };
            },
            .fnegate => .{ .fnegate = try mem.packedRead(SpirV.FNegate, &r, null) },
            .fadd => .{ .fadd = try mem.packedRead(SpirV.FAdd, &r, null) },
            .fmul => .{ .fmul = try mem.packedRead(SpirV.FMul, &r, null) },
            .matrix_times_vector => .{ .matrix_times_vector = try mem.packedRead(SpirV.MatrixTimesVector, &r, null) },
            .matrix_times_matrix => .{ .matrix_times_matrix = try mem.packedRead(SpirV.MatrixTimesMatrix, &r, null) },
            .fwidth => .{ .fwidth = try mem.packedRead(SpirV.FWidth, &r, null) },
            .label => .{ .label = try mem.packedRead(SpirV.Label, &r, null) },
            .op_return => .op_return,
            else => |name| {
                zut.dbg.print("TODO: Hit unsupported instruction at {d:.2}% \n\tInstruction: {}\n\tCode: {}\n\tWord count: {d}", .{
                    100 * zut.mem.asFloat(f32, reader.start) / zut.mem.asFloat(f32, reader.end),
                    name,
                    code,
                    word_count,
                });
                return null;
            },
        };
    }
};

fn readString(allocator: Allocator, r: *BufStream) ![]u8 {
    const len = r.readUntilDelimeter(null, 0);

    if (len == 0) {
        return &[0]u8{};
    }

    const dest = try allocator.alloc(u8, len);
    _ = r.readUntilDelimeter(dest, 0);
    r.skip(4) catch {};

    return dest;
}

fn readToEnd(T: type, allocator: Allocator, r: *BufStream) ![]T {
    const len = r.remainingBytes();

    if (len == 0) {
        return &[0]T{};
    }

    const dest = try allocator.alloc(T, len / @sizeOf(T));
    _ = r.readToEnd(std.mem.sliceAsBytes(dest));

    return dest;
}
