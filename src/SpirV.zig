const std = @import("std");
const zut = @import("zut");

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

const Header = extern struct {
    magic: u32,
    version: u32,
    generator: u32,
    bound: u32,
    schema: u32,
};

pub fn read(allocator: Allocator, r: *std.Io.Reader) !SpirV {
    const header = try r.takeStruct(Header, .little);
    if (header.magic != header_id) return error.InvalidSpirV;

    return .{
        .version = header.version,
        .generator = header.generator,
        .bound = header.bound,
        .schema = header.schema,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .reader = r,
    };
}

pub fn nextInstruction(self: *SpirV) !?Instruction {
    return Instruction.read(self.arena.allocator(), self.reader);
}

pub fn deinit(self: *SpirV) void {
    self.arena.deinit();
}

pub const Instruction = union(enum(u16)) {
    source: types.Source = 3,
    source_extension: types.SourceExtension = 4,
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
    shift_right_logical: types.ShiftRightLogical = 194,
    bitwise_and: types.BitwiseAnd = 199,
    ford_greater_than: types.FOrdGreaterThan = 186,
    convert_uto_f: types.ConvertUToF = 112,
    selection_merge: types.SelectionMerge = 247,
    label: types.Label = 248,
    branch_conditional: types.BranchConditional = 250,
    function_call: types.FunctionCall = 57,
    function_parameter: types.FunctionParameter = 55,
    sampled_image_combine: types.SampledImageCombine = 86,
    op_return: void = 253,
    unknown: u16 = 65535,
    return_value: types.ReturnValue = 254,
    kill: void = 252,
    branch: types.Branch = 249,
    fsub: types.FSub = 131,
    fdiv: types.FDiv = 136,
    imul: types.IMul = 132,
    iadd: types.IAdd = 128,
    umod: types.UMod = 137,
    dot: types.Dot = 148,
    bitwise_xor: types.BitwiseXor = 198,
    bitwise_or: types.BitwiseOr = 197,
    ford_less_than: types.FOrdLessThan = 184,
    ford_greater_than_equal: types.FOrdGreaterThanEqual = 190,
    ford_less_than_equal: types.FOrdLessThanEqual = 188,
    ugreater_than: types.UGreaterThan = 172,
    bitcast: types.Bitcast = 124,
    convert_sto_f: types.ConvertSToF = 111,
    convert_fto_s: types.ConvertFToS = 110,
    convert_fto_u: types.ConvertFToU = 109,
    shift_left_logical: types.ShiftLeftLogical = 196,
    shift_right_arithmetic: types.ShiftRightArithmetic = 195,
    select: types.Select = 169,
    image: types.ImageExtract = 100,
    image_fetch: types.ImageFetch = 95,
    image_sample_dref_implicit_lod: types.ImageSampleDrefImplicitLod = 89,

    pub fn read(allocator: Allocator, r: *std.Io.Reader) !?Instruction {
        const first_word = r.takeInt(u32, .little) catch |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        };

        const code: types.Op = @enumFromInt(@as(u16, @truncate(first_word)));
        const word_count: u16 = @intCast(first_word >> 16);
        const remaining = word_count -| 1;

        var body = std.Io.Reader.fixed(try r.take(remaining * 4));

        return switch (code) {
            .source => {
                var s: types.Source = undefined;
                s.language = body.takeEnum(types.SourceLanguage, .little) catch |e| return e;
                s.version = try body.takeInt(u32, .little);
                s.file_id = body.takeInt(u32, .little) catch null;
                s.source = readString(allocator, &body) catch null;
                return .{ .source = s };
            },
            .source_extension => .{ .source_extension = .{
                .extension = try readString(allocator, &body),
            } },
            .name => {
                const target_id = try body.takeInt(u32, .little);
                return .{ .name = .{ .target_id = target_id, .name = try readString(allocator, &body) } };
            },
            .member_name => {
                const type_id = try body.takeInt(u32, .little);
                const idx = try body.takeInt(u32, .little);
                return .{ .member_name = .{ .type_id = type_id, .idx = idx, .name = try readString(allocator, &body) } };
            },
            .ext_inst_import => {
                const result_id = try body.takeInt(u32, .little);
                return .{ .ext_inst_import = .{ .result_id = result_id, .name = try readString(allocator, &body) } };
            },
            .ext_inst => .{ .ext_inst = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .set_id = try body.takeInt(u32, .little),
                .instruction = try body.takeInt(u32, .little),
                .operands = try readRestU32(allocator, &body),
            } },
            .memory_model => .{ .memory_model = .{
                .addressing_model = try body.takeEnum(types.AddressingModel, .little),
                .typ = try body.takeEnum(types.MemoryModelType, .little),
            } },
            .entry_point => {
                const execution_model = try body.takeEnum(types.ExecutionModel, .little);
                const id = try body.takeInt(u32, .little);
                const name = try readString(allocator, &body);
                return .{ .entry_point = .{
                    .execution_model = execution_model,
                    .id = id,
                    .name = name,
                    .interface = try readRestU32(allocator, &body),
                } };
            },
            .execution_mode => {
                const entry_point_id = try body.takeInt(u32, .little);
                const mode = try body.takeEnum(types.ExecutionModeType, .little);
                return .{ .execution_mode = .{
                    .entry_point_id = entry_point_id,
                    .mode = mode,
                    .operands = try readRestU32(allocator, &body),
                } };
            },
            .capability => .{ .capability = try body.takeEnum(types.Capability, .little) },
            .type_void => .{ .type = .{ .result_id = try body.takeInt(u32, .little), .info = .void } },
            .type_bool => .{ .type = .{ .result_id = try body.takeInt(u32, .little), .info = .bool } },
            .type_sampler => .{ .type = .{ .result_id = try body.takeInt(u32, .little), .info = .sampler } },
            .type_int => {
                const result_id = try body.takeInt(u32, .little);
                const width = try body.takeInt(u32, .little);
                const signedness = try body.takeEnum(types.Signedness, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .int = .{ .width = width, .signedness = signedness } } } };
            },
            .type_vector => {
                const result_id = try body.takeInt(u32, .little);
                const component_type = try body.takeInt(u32, .little);
                const component_count = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .vector = .{ .component_type = component_type, .component_count = component_count } } } };
            },
            .type_matrix => {
                const result_id = try body.takeInt(u32, .little);
                const column_type_id = try body.takeInt(u32, .little);
                const column_count = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .matrix = .{ .column_type_id = column_type_id, .column_count = column_count } } } };
            },
            .type_sampled_image => {
                const result_id = try body.takeInt(u32, .little);
                const image_type_id = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .sampled_image = .{ .image_type_id = image_type_id } } } };
            },
            .type_array => {
                const result_id = try body.takeInt(u32, .little);
                const element_type_id = try body.takeInt(u32, .little);
                const length = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .array = .{ .element_type_id = element_type_id, .length = length } } } };
            },
            .type_float => {
                const result_id = try body.takeInt(u32, .little);
                const width = try body.takeInt(u32, .little);
                const encoding = body.takeInt(u32, .little) catch null;
                return .{ .type = .{ .result_id = result_id, .info = .{ .float = .{ .width = width, .encoding = encoding } } } };
            },
            .type_image => {
                const result_id = try body.takeInt(u32, .little);
                const sampled_type_id = try body.takeInt(u32, .little);
                const dim = try body.takeEnum(types.Dim, .little);
                const depth = try body.takeEnum(types.Depth, .little);
                const arrayed = try body.takeEnum(types.Arrayed, .little);
                const ms = try body.takeEnum(types.Ms, .little);
                const sampled = try body.takeEnum(types.Sampled, .little);
                const format = try body.takeEnum(types.ImageFormat, .little);
                const access_qualifier = body.takeEnum(types.AccessQualifier, .little) catch null;
                return .{ .type = .{ .result_id = result_id, .info = .{ .image = .{
                    .sampled_type_id = sampled_type_id,
                    .dim = dim,
                    .depth = depth,
                    .arrayed = arrayed,
                    .ms = ms,
                    .sampled = sampled,
                    .format = format,
                    .access_qualifier = access_qualifier,
                } } } };
            },
            .type_struct => {
                const result_id = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .@"struct" = .{ .member_ids = try readRestU32(allocator, &body) } } } };
            },
            .type_function => {
                const result_id = try body.takeInt(u32, .little);
                const return_type_id = try body.takeInt(u32, .little);
                return .{ .type = .{ .result_id = result_id, .info = .{ .function = .{
                    .return_type_id = return_type_id,
                    .parameter_ids = try readRestU32(allocator, &body),
                } } } };
            },
            .type_pointer => .{ .type_pointer = .{
                .result_id = try body.takeInt(u32, .little),
                .storage_class = try body.takeEnum(types.StorageClass, .little),
                .type_id = try body.takeInt(u32, .little),
            } },
            .constant => .{ .constant = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .value = try readRestU32(allocator, &body),
            } },
            .constant_composite => .{ .constant_composite = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .constituent_ids = try readRestU32(allocator, &body),
            } },
            .spec_constant => .{ .spec_constant = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .value = try readRestU32(allocator, &body),
            } },
            .function => .{ .function = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .fn_control = try body.takeEnum(types.FunctionControl, .little),
                .fn_type_id = try body.takeInt(u32, .little),
            } },
            .function_end => .function_end,
            .variable => .{ .variable = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .storage_class = try body.takeEnum(types.StorageClass, .little),
                .initializer_id = body.takeInt(u32, .little) catch null,
            } },
            .load => .{ .load = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .pointer_id = try body.takeInt(u32, .little),
                .memory_operands = readRestU32(allocator, &body) catch &[0]u32{},
            } },
            .store => .{ .store = .{
                .pointer_id = try body.takeInt(u32, .little),
                .object_id = try body.takeInt(u32, .little),
                .memory_operands = readRestU32(allocator, &body) catch &[0]u32{},
            } },
            .access_chain => .{ .access_chain = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .base_id = try body.takeInt(u32, .little),
                .index_ids = try readRestU32(allocator, &body),
            } },
            .decorate => {
                const target_id = try body.takeInt(u32, .little);
                const decoration = try body.takeEnum(types.Decoration, .little);
                return .{ .decorate = .{
                    .target_id = target_id,
                    .decoration = decoration,
                    .operands = readRestU32(allocator, &body) catch &[0]u32{},
                } };
            },
            .member_decorate => {
                const struct_type_id = try body.takeInt(u32, .little);
                const member_idx = try body.takeInt(u32, .little);
                const decoration = try body.takeEnum(types.Decoration, .little);
                return .{ .member_decorate = .{
                    .struct_type_id = struct_type_id,
                    .member_idx = member_idx,
                    .decoration = decoration,
                    .operands = readRestU32(allocator, &body) catch &[0]u32{},
                } };
            },
            .vector_shuffle => .{ .vector_shuffle = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .vector1_id = try body.takeInt(u32, .little),
                .vector2_id = try body.takeInt(u32, .little),
                .components = readRestU32(allocator, &body) catch &[0]u32{},
            } },
            .composite_construct => .{ .composite_construct = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .constituent_ids = try readRestU32(allocator, &body),
            } },
            .composite_extract => .{ .composite_extract = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .composite_id = try body.takeInt(u32, .little),
                .index_ids = try readRestU32(allocator, &body),
            } },
            .image_sample_implicit_lod => .{ .image_sample_implicit_lod = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .sampled_image_id = try body.takeInt(u32, .little),
                .coordinate_id = try body.takeInt(u32, .little),
                .image_operands = readImageOperands(allocator, &body) catch &[0]types.ImageOperands{},
            } },
            .fnegate => .{ .fnegate = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand_id = try body.takeInt(u32, .little),
            } },
            .fadd => .{ .fadd = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .fmul => .{ .fmul = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .vector_times_scalar => .{ .vector_times_scalar = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .vector_id = try body.takeInt(u32, .little),
                .scalar_id = try body.takeInt(u32, .little),
            } },
            .matrix_times_vector => .{ .matrix_times_vector = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .matrix_id = try body.takeInt(u32, .little),
                .vector_id = try body.takeInt(u32, .little),
            } },
            .matrix_times_matrix => .{ .matrix_times_matrix = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .left_matrix_id = try body.takeInt(u32, .little),
                .right_matrix_id = try body.takeInt(u32, .little),
            } },
            .fwidth => .{ .fwidth = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .p_id = try body.takeInt(u32, .little),
            } },
            .shift_right_logical => .{ .shift_right_logical = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .base_id = try body.takeInt(u32, .little),
                .shift_id = try body.takeInt(u32, .little),
            } },
            .bitwise_and => .{ .bitwise_and = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .ford_greater_than => .{ .ford_greater_than = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .convert_uto_f => .{ .convert_uto_f = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .unsigned_value_id = try body.takeInt(u32, .little),
            } },
            .selection_merge => .{ .selection_merge = .{
                .merge_block_id = try body.takeInt(u32, .little),
                .selection_control = try body.takeInt(u32, .little),
            } },
            .label => .{ .label = .{ .result_id = try body.takeInt(u32, .little) } },
            .branch_conditional => .{ .branch_conditional = .{
                .condition_id = try body.takeInt(u32, .little),
                .true_label_id = try body.takeInt(u32, .little),
                .false_label_id = try body.takeInt(u32, .little),
                .branch_weights = readRestU32(allocator, &body) catch &[0]u32{},
            } },
            .function_call => {
                const result_type_id = try body.takeInt(u32, .little);
                const result_id = try body.takeInt(u32, .little);
                const function_id = try body.takeInt(u32, .little);
                return .{ .function_call = .{
                    .result_type_id = result_type_id,
                    .result_id = result_id,
                    .function_id = function_id,
                    .argument_ids = try readRestU32(allocator, &body),
                } };
            },
            .function_parameter => .{ .function_parameter = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
            } },
            .sampled_image => .{ .sampled_image_combine = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .image_id = try body.takeInt(u32, .little),
                .sampler_id = try body.takeInt(u32, .little),
            } },
            .op_return => .op_return,
            .return_value => .{ .return_value = .{
                .value_id = try body.takeInt(u32, .little),
            } },
            .kill => .kill,
            .branch => .{ .branch = .{
                .target_label_id = try body.takeInt(u32, .little),
            } },
            .fsub => .{ .fsub = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .fdiv => .{ .fdiv = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .imul => .{ .imul = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .iadd => .{ .iadd = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .umod => .{ .umod = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .dot => .{ .dot = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .vector1_id = try body.takeInt(u32, .little),
                .vector2_id = try body.takeInt(u32, .little),
            } },
            .bitwise_xor => .{ .bitwise_xor = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .bitwise_or => .{ .bitwise_or = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .ford_less_than => .{ .ford_less_than = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .ford_greater_than_equal => .{ .ford_greater_than_equal = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .ford_less_than_equal => .{ .ford_less_than_equal = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .ugreater_than => .{ .ugreater_than = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand1_id = try body.takeInt(u32, .little),
                .operand2_id = try body.takeInt(u32, .little),
            } },
            .bitcast => .{ .bitcast = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .operand_id = try body.takeInt(u32, .little),
            } },
            .convert_sto_f => .{ .convert_sto_f = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .signed_value_id = try body.takeInt(u32, .little),
            } },
            .convert_fto_s => .{ .convert_fto_s = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .float_value_id = try body.takeInt(u32, .little),
            } },
            .convert_fto_u => .{ .convert_fto_u = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .float_value_id = try body.takeInt(u32, .little),
            } },
            .shift_left_logical => .{ .shift_left_logical = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .base_id = try body.takeInt(u32, .little),
                .shift_id = try body.takeInt(u32, .little),
            } },
            .shift_right_arithmetic => .{ .shift_right_arithmetic = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .base_id = try body.takeInt(u32, .little),
                .shift_id = try body.takeInt(u32, .little),
            } },
            .select => .{ .select = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .condition_id = try body.takeInt(u32, .little),
                .object1_id = try body.takeInt(u32, .little),
                .object2_id = try body.takeInt(u32, .little),
            } },
            .image => .{ .image = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .sampled_image_id = try body.takeInt(u32, .little),
            } },
            .image_fetch => .{ .image_fetch = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .image_id = try body.takeInt(u32, .little),
                .coordinate_id = try body.takeInt(u32, .little),
                .image_operands = readImageOperands(allocator, &body) catch &[0]types.ImageOperands{},
            } },
            .image_sample_dref_implicit_lod => .{ .image_sample_dref_implicit_lod = .{
                .result_type_id = try body.takeInt(u32, .little),
                .result_id = try body.takeInt(u32, .little),
                .sampled_image_id = try body.takeInt(u32, .little),
                .coordinate_id = try body.takeInt(u32, .little),
                .dref_id = try body.takeInt(u32, .little),
                .image_operands = readImageOperands(allocator, &body) catch &[0]types.ImageOperands{},
            } },
            else => {
                std.log.warn("unhandled SPIR-V opcode: {s} ({d})", .{ @tagName(code), @intFromEnum(code) });
                return .{ .unknown = @intFromEnum(code) };
            },
        };
    }
};

fn readString(allocator: Allocator, r: *std.Io.Reader) ![]u8 {
    const str = try r.takeDelimiterExclusive(0);
    if (str.len == 0) return &[0]u8{};
    return allocator.dupe(u8, str);
}

fn readRestU32(allocator: Allocator, r: *std.Io.Reader) ![]u32 {
    const remaining = r.buffered();
    if (remaining.len == 0) return &[0]u32{};

    const dest = try allocator.alloc(u32, remaining.len / 4);
    for (dest, 0..) |*v, i| v.* = std.mem.readInt(u32, remaining[i * 4 ..][0..4], .little);
    r.toss(remaining.len);
    return dest;
}

fn readImageOperands(allocator: Allocator, r: *std.Io.Reader) ![]types.ImageOperands {
    if (r.bufferedLen() == 0) return &[0]types.ImageOperands{};

    const mask = try r.takeInt(u32, .little);
    var flags: [8]types.ImageOperands = undefined;
    var count: usize = 0;

    inline for (@typeInfo(types.ImageOperands).@"enum".fields) |field| {
        const bit: u32 = 1 << field.value;
        if (mask & bit != 0) {
            flags[count] = @enumFromInt(field.value);
            count += 1;
        }
    }

    r.discardAll(r.bufferedLen()) catch {};

    return allocator.dupe(types.ImageOperands, flags[0..count]);
}
