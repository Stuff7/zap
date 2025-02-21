pub const Source = struct {
    language: SourceLanguage,
    version: u32,
    file_id: ?u32,
    source: ?[]u8,
};

pub const Name = struct {
    target_id: u32,
    name: []u8,
};

pub const MemberName = struct {
    type_id: u32,
    id: u32,
    name: []u8,
};

pub const ExtInstImport = struct {
    result_id: u32,
    name: []u8,
};

pub const ExtInst = struct {
    result_type_id: u32,
    result_id: u32,
    set_id: u32,
    instruction: u32,
    operands: []u32,
};

pub const MemoryModel = struct {
    addressing_model: AddressingModel,
    typ: MemoryModelType,
};

pub const EntryPoint = struct {
    execution_model: ExecutionModel,
    id: u32,
    name: []u8,
    interface: []u32,
};

pub const ExecutionMode = struct {
    entry_point_id: u32,
    mode: ExecutionModeType,
    operands: []u32,
};

pub const Type = struct {
    result_id: u32,
    info: Info,

    pub const Info = union(enum) {
        void,
        bool,
        int: Int,
        float: Float,
        vector: Vector,
        matrix: Matrix,
        image: Image,
        sampled_image: SampledImage,
        array: Array,
        @"struct": Struct,
        function: Type.Function,
    };

    pub const Int = struct {
        width: u32,
        signedness: Signedness,
    };

    pub const Float = struct {
        width: u32,
        encoding: ?u32,
    };

    pub const Vector = struct {
        component_type: u32,
        component_count: u32,
    };

    pub const Matrix = struct {
        column_type_id: u32,
        column_count: u32,
    };

    pub const Image = struct {
        sampled_type_id: u32,
        dim: Dim,
        depth: Depth,
        arrayed: Arrayed,
        ms: Ms,
        sampeld: Sampled,
        format: ImageFormat,
        access_qualifier: ?AccessQualifier,
    };

    pub const SampledImage = struct {
        image_type_id: u32,
    };

    pub const Struct = struct {
        member_ids: []u32,
    };

    pub const Function = struct {
        return_type_id: u32,
        parameter_ids: []u32,
    };

    pub const Array = struct {
        element_type_id: u32,
        length: u32,
    };
};

pub const TypePointer = struct {
    result_id: u32,
    storage_class: StorageClass,
    type_id: u32,
};

pub const Constant = struct {
    result_type_id: u32,
    result_id: u32,
    value: []u32,
};

pub const ConstantComposite = struct {
    result_type_id: u32,
    result_id: u32,
    constituent_ids: []u32,
};

pub const SpecConstant = struct {
    result_type_id: u32,
    result_id: u32,
    value: []u32,
};

pub const Function = struct {
    result_type_id: u32,
    result_id: u32,
    fn_control: FunctionControl,
    fn_type_id: u32,
};

pub const Variable = struct {
    result_type_id: u32,
    result_id: u32,
    storage_class: StorageClass,
    initializer_id: ?u32,
};

pub const Load = struct {
    result_type_id: u32,
    result_id: u32,
    pointer_id: u32,
    memory_operands: []u32,
};

pub const Store = struct {
    pointer_id: u32,
    object_id: u32,
    memory_operands: []u32,
};

pub const AccessChain = struct {
    result_type_id: u32,
    result_id: u32,
    base_id: u32,
    index_ids: []u32,
};

pub const Decorate = struct {
    target_id: u32,
    decoration: Decoration,
    operands: []u32,
};

pub const MemberDecorate = struct {
    struct_type_id: u32,
    member_idx: u32,
    decoration: Decoration,
    operands: []u32,
};

pub const CompositeConstruct = struct {
    result_type_id: u32,
    result_id: u32,
    constituent_ids: []u32,
};

pub const CompositeExtract = struct {
    result_type_id: u32,
    result_id: u32,
    composite_id: u32,
    index_ids: []u32,
};

pub const ImageSampleImplicitLod = struct {
    result_type_id: u32,
    result_id: u32,
    sampled_image_id: u32,
    coordinate_id: u32,
    image_operands: []ImageOperands,
};

pub const FNegate = struct {
    result_type_id: u32,
    result_id: u32,
    operand_id: u32,
};

pub const FAdd = struct {
    result_type_id: u32,
    result_id: u32,
    operand1_id: u32,
    operand2_id: u32,
};

pub const FMul = struct {
    result_type_id: u32,
    result_id: u32,
    operand1_id: u32,
    operand2_id: u32,
};

pub const MatrixTimesVector = struct {
    result_type_id: u32,
    result_id: u32,
    matrix_id: u32,
    vector_id: u32,
};

pub const MatrixTimesMatrix = struct {
    result_type_id: u32,
    result_id: u32,
    left_matrix_id: u32,
    right_matrix_id: u32,
};

pub const FWidth = struct {
    result_type_id: u32,
    result_id: u32,
    p_id: u32,
};

pub const Label = struct {
    result_id: u32,
};

pub const AddressingModel = enum(u32) {
    logical = 0,
    physical32 = 1,
    physical64 = 2,
};

pub const MemoryModelType = enum(u32) {
    simple = 0,
    glsl450 = 1,
    openCL = 2,
};

pub const ExecutionModel = enum(u32) {
    vertex = 0,
    tessellation_control = 1,
    tessellation_evaluation = 2,
    geometry = 3,
    fragment = 4,
    gl_compute = 5,
    kernel = 6,
};

pub const ExecutionModeType = enum(u32) {
    invocations = 0,
    spacing_equal = 1,
    spacing_fractional_even = 2,
    spacing_fractional_odd = 3,
    vertex_order_cw = 4,
    vertex_order_ccw = 5,
    pixel_center_integer = 6,
    origin_upper_left = 7,
    origin_lower_left = 8,
    early_fragment_tests = 9,
    point_mode = 10,
    xfb = 11,
    depth_replacing = 12,
    depth_greater = 14,
    depth_less = 15,
    depth_unchanged = 16,
    local_size = 17,
    local_size_hint = 18,
    input_points = 19,
    input_lines = 20,
    input_lines_adjacency = 21,
    triangles = 22,
    input_triangles_adjacency = 23,
    quads = 24,
    isolines = 25,
    output_vertices = 26,
    output_points = 27,
    output_line_strip = 28,
    output_triangle_strip = 29,
    vec_type_hint = 30,
    contraction_off = 31,
    post_depth_coverage = 4446,
    stencil_ref_replacing_ext = 5027,
};

pub const SourceLanguage = enum(u32) {
    unknown = 0,
    essl = 1,
    glsl = 2,
    opencl_c = 3,
    opencl_cpp = 4,
    hlsl = 5,
};

pub const Decoration = enum(u32) {
    relaxed_precision = 0,
    spec_id = 1,
    block = 2,
    buffer_block = 3,
    row_major = 4,
    col_major = 5,
    array_stride = 6,
    matrix_stride = 7,
    g_lslshared = 8,
    g_lslpacked = 9,
    c_packed = 10,
    built_in = 11,
    no_perspective = 13,
    flat = 14,
    patch = 15,
    centroid = 16,
    sample = 17,
    invariant = 18,
    restrict = 19,
    aliased = 20,
    decoration_volatile = 21,
    constant = 22,
    coherent = 23,
    non_writable = 24,
    non_readable = 25,
    uniform = 26,
    saturated_conversion = 28,
    stream = 29,
    location = 30,
    component = 31,
    index = 32,
    binding = 33,
    descriptor_set = 34,
    offset = 35,
    xfb_buffer = 36,
    xfb_stride = 37,
    func_param_attr = 38,
    f_prounding_mode = 39,
    f_pfast_math_mode = 40,
    linkage_attributes = 41,
    no_contraction = 42,
    input_attachment_index = 43,
    alignment = 44,
    explicit_interp_amd = 4999,
    override_coverage_nv = 5248,
    passthrough_nv = 5250,
    viewport_relative_nv = 5252,
    secondary_viewport_relative_nv = 5256,
    hlsl_counter_buffer_google = 5634,
    hlsl_semantic_google = 5635,
};

pub const StorageClass = enum(u32) {
    uniform_constant = 0,
    input = 1,
    uniform = 2,
    output = 3,
    workgroup = 4,
    cross_workgroup = 5,
    private = 6,
    function = 7,
    generic = 8,
    push_constant = 9,
    atomic_counter = 10,
    image = 11,
    storage_buffer = 12,
};

pub const Signedness = enum(u32) {
    unsigned = 0,
    signed = 1,
};

pub const FunctionControl = enum(u32) {
    fn_inline = 0,
    dont_inline = 1,
    pure = 2,
    fn_const = 3,
};

pub const Dim = enum(u32) {
    dim1d = 0,
    dim2d = 1,
    dim3d = 2,
    cube = 3,
    rect = 4,
    buffer = 5,
    subpass_data = 6,
};

pub const Depth = enum(u32) {
    no_depth = 0,
    depth = 1,
    no_indication = 2,
};

pub const Arrayed = enum(u32) {
    non_arrayed = 0,
    arrayed = 1,
};

pub const Ms = enum(u32) {
    single_sampled = 0,
    multi_sampled = 1,
};

pub const Sampled = enum(u32) {
    run_time = 0,
    sampling_op_compatible = 1,
    rw_op_compatible = 2,
};

pub const ImageFormat = enum(u32) {
    unknown = 0,
    rgba32f = 1,
    rgba16f = 2,
    r32f = 3,
    rgba8 = 4,
    rgba8_snorm = 5,
    rg32f = 6,
    rg16f = 7,
    r11f_g11f_b10f = 8,
    r16f = 9,
    rgba16 = 10,
    rgb10_a2 = 11,
    rg16 = 12,
    rg8 = 13,
    r16 = 14,
    r8 = 15,
    rgba16_snorm = 16,
    rg16_snorm = 17,
    rg8_snorm = 18,
    r16_snorm = 19,
    r8_snorm = 20,
    rgba32i = 21,
    rgba16i = 22,
    rgba8i = 23,
    r32i = 24,
    rg32i = 25,
    rg16i = 26,
    rg8i = 27,
    r16i = 28,
    r8i = 29,
    rgba32ui = 30,
    rgba16ui = 31,
    rgba8ui = 32,
    r32ui = 33,
    rgb10a2ui = 34,
    rg32ui = 35,
    rg16ui = 36,
    rg8ui = 37,
    r16ui = 38,
    r8ui = 39,
};

pub const AccessQualifier = enum(u32) {
    read_only = 0,
    write_only = 1,
    read_write = 2,
};

pub const ImageOperands = enum(u32) {
    bias = 0,
    lod = 1,
    grad = 2,
    const_offset = 3,
    offset = 4,
    const_offsets = 5,
    sample = 6,
    min_lod = 7,
};

pub const Op = enum(u16) {
    nop = 0,
    undef = 1,
    source_continued = 2,
    source = 3,
    source_extension = 4,
    name = 5,
    member_name = 6,
    string = 7,
    line = 8,
    extension = 10,
    ext_inst_import = 11,
    ext_inst = 12,
    memory_model = 14,
    entry_point = 15,
    execution_mode = 16,
    capability = 17,
    type_void = 19,
    type_bool = 20,
    type_int = 21,
    type_float = 22,
    type_vector = 23,
    type_matrix = 24,
    type_image = 25,
    type_sampler = 26,
    type_sampled_image = 27,
    type_array = 28,
    type_runtime_array = 29,
    type_struct = 30,
    type_opaque = 31,
    type_pointer = 32,
    type_function = 33,
    type_event = 34,
    type_device_event = 35,
    type_reserve_id = 36,
    type_queue = 37,
    type_pipe = 38,
    type_forward_pointer = 39,
    constant_true = 41,
    constant_false = 42,
    constant = 43,
    constant_composite = 44,
    constant_sampler = 45,
    constant_null = 46,
    spec_constant_true = 48,
    spec_constant_false = 49,
    spec_constant = 50,
    spec_constant_composite = 51,
    spec_constant_op = 52,
    function = 54,
    function_parameter = 55,
    function_end = 56,
    function_call = 57,
    variable = 59,
    image_texel_pointer = 60,
    load = 61,
    store = 62,
    copy_memory = 63,
    copy_memory_sized = 64,
    access_chain = 65,
    in_bounds_access_chain = 66,
    ptr_access_chain = 67,
    array_length = 68,
    generic_ptr_mem_semantics = 69,
    in_bounds_ptr_access_chain = 70,
    decorate = 71,
    member_decorate = 72,
    decoration_group = 73,
    group_decorate = 74,
    group_member_decorate = 75,
    vector_extract_dynamic = 77,
    vector_insert_dynamic = 78,
    vector_shuffle = 79,
    composite_construct = 80,
    composite_extract = 81,
    composite_insert = 82,
    copy_object = 83,
    transpose = 84,
    sampled_image = 86,
    image_sample_implicit_lod = 87,
    image_sample_explicit_lod = 88,
    image_sample_dref_implicit_lod = 89,
    image_sample_dref_explicit_lod = 90,
    image_sample_proj_implicit_lod = 91,
    image_sample_proj_explicit_lod = 92,
    image_sample_proj_dref_implicit_lod = 93,
    image_sample_proj_dref_explicit_lod = 94,
    image_fetch = 95,
    image_gather = 96,
    image_dref_gather = 97,
    image_read = 98,
    image_write = 99,
    image = 100,
    image_query_format = 101,
    image_query_order = 102,
    image_query_size_lod = 103,
    image_query_size = 104,
    image_query_lod = 105,
    image_query_levels = 106,
    image_query_samples = 107,
    convert_fto_u = 109,
    convert_fto_s = 110,
    convert_sto_f = 111,
    convert_uto_f = 112,
    uconvert = 113,
    sconvert = 114,
    fconvert = 115,
    quantize_to_f16 = 116,
    convert_ptr_to_u = 117,
    sat_convert_sto_u = 118,
    sat_convert_uto_s = 119,
    convert_uto_ptr = 120,
    ptr_cast_to_generic = 121,
    generic_cast_to_ptr = 122,
    generic_cast_to_ptr_explicit = 123,
    bitcast = 124,
    snegate = 126,
    fnegate = 127,
    iadd = 128,
    fadd = 129,
    isub = 130,
    fsub = 131,
    imul = 132,
    fmul = 133,
    udiv = 134,
    sdiv = 135,
    fdiv = 136,
    umod = 137,
    srem = 138,
    smod = 139,
    frem = 140,
    fmod = 141,
    vector_times_scalar = 142,
    matrix_times_scalar = 143,
    vector_times_matrix = 144,
    matrix_times_vector = 145,
    matrix_times_matrix = 146,
    outer_product = 147,
    dot = 148,
    iadd_carry = 149,
    isub_borrow = 150,
    umul_extended = 151,
    smul_extended = 152,
    any = 154,
    all = 155,
    is_nan = 156,
    is_inf = 157,
    is_finite = 158,
    is_normal = 159,
    sign_bit_set = 160,
    less_or_greater = 161,
    ordered = 162,
    unordered = 163,
    logical_equal = 164,
    logical_not_equal = 165,
    logical_or = 166,
    logical_and = 167,
    logical_not = 168,
    select = 169,
    iequal = 170,
    inot_equal = 171,
    ugreater_than = 172,
    sgreater_than = 173,
    ugreater_than_equal = 174,
    sgreater_than_equal = 175,
    uless_than = 176,
    sless_than = 177,
    uless_than_equal = 178,
    sless_than_equal = 179,
    ford_equal = 180,
    funord_equal = 181,
    ford_not_equal = 182,
    funord_not_equal = 183,
    ford_less_than = 184,
    funord_less_than = 185,
    ford_greater_than = 186,
    funord_greater_than = 187,
    ford_less_than_equal = 188,
    funord_less_than_equal = 189,
    ford_greater_than_equal = 190,
    funord_greater_than_equal = 191,
    shift_right_logical = 194,
    shift_right_arithmetic = 195,
    shift_left_logical = 196,
    bitwise_or = 197,
    bitwise_xor = 198,
    bitwise_and = 199,
    not = 200,
    bit_field_insert = 201,
    bit_field_sextract = 202,
    bit_field_uextract = 203,
    bit_reverse = 204,
    bit_count = 205,
    dpdx = 207,
    dpdy = 208,
    fwidth = 209,
    dpdx_fine = 210,
    dpdy_fine = 211,
    fwidth_fine = 212,
    dpdx_coarse = 213,
    dpdy_coarse = 214,
    fwidth_coarse = 215,
    emit_vertex = 218,
    end_primitive = 219,
    emit_stream_vertex = 220,
    end_stream_primitive = 221,
    control_barrier = 224,
    memory_barrier = 225,
    atomic_load = 227,
    atomic_store = 228,
    atomic_exchange = 229,
    atomic_compare_exchange = 230,
    atomic_compare_exchange_weak = 231,
    atomic_iincrement = 232,
    atomic_idecrement = 233,
    atomic_iadd = 234,
    atomic_isub = 235,
    atomic_smin = 236,
    atomic_umin = 237,
    atomic_smax = 238,
    atomic_umax = 239,
    atomic_and = 240,
    atomic_or = 241,
    atomic_xor = 242,
    phi = 245,
    loop_merge = 246,
    selection_merge = 247,
    label = 248,
    branch = 249,
    branch_conditional = 250,
    op_switch = 251,
    kill = 252,
    op_return = 253,
    return_value = 254,
    op_unreachable = 255,
    lifetime_start = 256,
    lifetime_stop = 257,
    group_async_copy = 259,
    group_wait_events = 260,
    group_all = 261,
    group_any = 262,
    group_broadcast = 263,
    group_iadd = 264,
    group_fadd = 265,
    group_fmin = 266,
    group_umin = 267,
    group_smin = 268,
    group_fmax = 269,
    group_umax = 270,
    group_smax = 271,
    read_pipe = 274,
    write_pipe = 275,
    reserved_read_pipe = 276,
    reserved_write_pipe = 277,
    reserve_read_pipe_packets = 278,
    reserve_write_pipe_packets = 279,
    commit_read_pipe = 280,
    commit_write_pipe = 281,
    is_valid_reserve_id = 282,
    get_num_pipe_packets = 283,
    get_max_pipe_packets = 284,
    group_reserve_read_pipe_packets = 285,
    group_reserve_write_pipe_packets = 286,
    group_commit_read_pipe = 287,
    group_commit_write_pipe = 288,
    enqueue_marker = 291,
    enqueue_kernel = 292,
    get_kernel_ndrange_sub_group_count = 293,
    get_kernel_ndrange_max_sub_group_size = 294,
    get_kernel_work_group_size = 295,
    get_kernel_preferred_work_group_size_multiple = 296,
    retain_event = 297,
    release_event = 298,
    create_user_event = 299,
    is_valid_event = 300,
    set_user_event_status = 301,
    capture_event_profiling_info = 302,
    get_default_queue = 303,
    build_ndrange = 304,
    image_sparse_sample_implicit_lod = 305,
    image_sparse_sample_explicit_lod = 306,
    image_sparse_sample_dref_implicit_lod = 307,
    image_sparse_sample_dref_explicit_lod = 308,
    image_sparse_sample_proj_implicit_lod = 309,
    image_sparse_sample_proj_explicit_lod = 310,
    image_sparse_sample_proj_dref_implicit_lod = 311,
    image_sparse_sample_proj_dref_explicit_lod = 312,
    image_sparse_fetch = 313,
    image_sparse_gather = 314,
    image_sparse_dref_gather = 315,
    image_sparse_texels_resident = 316,
    no_line = 317,
    atomic_flag_test_and_set = 318,
    atomic_flag_clear = 319,
    image_sparse_read = 320,
    decorate_id = 332,
    subgroup_ballot_khr = 4421,
    subgroup_first_invocation_khr = 4422,
    subgroup_all_khr = 4428,
    subgroup_any_khr = 4429,
    subgroup_all_equal_khr = 4430,
    subgroup_read_invocation_khr = 4432,
    group_iadd_non_uniform_amd = 5000,
    group_fadd_non_uniform_amd = 5001,
    group_fmin_non_uniform_amd = 5002,
    group_umin_non_uniform_amd = 5003,
    group_smin_non_uniform_amd = 5004,
    group_fmax_non_uniform_amd = 5005,
    group_umax_non_uniform_amd = 5006,
    group_smax_non_uniform_amd = 5007,
    fragment_mask_fetch_amd = 5011,
    fragment_fetch_amd = 5012,
    subgroup_shuffle_intel = 5571,
    subgroup_shuffle_down_intel = 5572,
    subgroup_shuffle_up_intel = 5573,
    subgroup_shuffle_xor_intel = 5574,
    subgroup_block_read_intel = 5575,
    subgroup_block_write_intel = 5576,
    subgroup_image_block_read_intel = 5577,
    subgroup_image_block_write_intel = 5578,
    decorate_string_google = 5632,
    member_decorate_string_google = 5633,
};

pub const Capability = enum(u32) {
    matrix = 0,
    shader = 1,
    geometry = 2,
    tessellation = 3,
    addresses = 4,
    linkage = 5,
    kernel = 6,
    vector16 = 7,
    float16_buffer = 8,
    float16 = 9,
    float64 = 10,
    int64 = 11,
    int64_atomics = 12,
    image_basic = 13,
    image_read_write = 14,
    image_mipmap = 15,
    pipes = 17,
    groups = 18,
    device_enqueue = 19,
    literal_sampler = 20,
    atomic_storage = 21,
    int16 = 22,
    tessellation_point_size = 23,
    geometry_point_size = 24,
    image_gather_extended = 25,
    storage_image_multisample = 27,
    uniform_buffer_array_dynamic_indexing = 28,
    sampled_image_array_dynamic_indexing = 29,
    storage_buffer_array_dynamic_indexing = 30,
    storage_image_array_dynamic_indexing = 31,
    clip_distance = 32,
    cull_distance = 33,
    image_cube_array = 34,
    sample_rate_shading = 35,
    image_rect = 36,
    sampled_rect = 37,
    generic_pointer = 38,
    int8 = 39,
    input_attachment = 40,
    sparse_residency = 41,
    min_lod = 42,
    sampled1d = 43,
    image1d = 44,
    sampled_cube_array = 45,
    sampled_buffer = 46,
    image_buffer = 47,
    image_msarray = 48,
    storage_image_extended_formats = 49,
    image_query = 50,
    derivative_control = 51,
    interpolation_function = 52,
    transform_feedback = 53,
    geometry_streams = 54,
    storage_image_read_without_format = 55,
    storage_image_write_without_format = 56,
    multi_viewport = 57,
    subgroup_ballot_khr = 4423,
    draw_parameters = 4427,
    subgroup_vote_khr = 4431,
    storage_uniform_buffer_block16 = 4433,
    storage_uniform16 = 4434,
    storage_push_constant16 = 4435,
    storage_input_output16 = 4436,
    device_group = 4437,
    multi_view = 4439,
    variable_pointers_storage_buffer = 4441,
    variable_pointers = 4442,
    atomic_storage_ops = 4445,
    sample_mask_post_depth_coverage = 4447,
    image_gather_bias_lod_amd = 5009,
    fragment_mask_amd = 5010,
    stencil_export_ext = 5013,
    image_read_write_lod_amd = 5015,
    sample_mask_override_coverage_nv = 5249,
    geometry_shader_passthrough_nv = 5251,
    shader_viewport_index_layer_ext = 5254,
    shader_viewport_mask_nv = 5255,
    shader_stereo_view_nv = 5259,
    per_view_attributes_nv = 5260,
    subgroup_shuffle_intel = 5568,
    subgroup_buffer_block_iointel = 5569,
    subgroup_image_block_iointel = 5570,
};
