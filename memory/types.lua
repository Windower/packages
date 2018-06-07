local structs = require('structs')

local struct = structs.struct

local tag = structs.tag
local string = structs.string
local data = structs.data
local encoded = structs.encoded

local int8 = structs.int8
local int16 = structs.int16
local int32 = structs.int32
local int64 = structs.int64
local uint8 = structs.uint8
local uint16 = structs.uint16
local uint32 = structs.uint32
local uint64 = structs.uint64
local float = structs.float
local double = structs.double
local bool = structs.bool

local ptr = structs.ptr

local types = {}

local render = struct {
    framerate_divisor       = {0x030, uint32},
    aspect_ratio            = {0x2F0, float},
}

local point = struct {
    x                       ={0x04, float},
    z                       ={0x08, float},
    y                       ={0x0C, float}, 
}

local animation = struct {
    value                   ={0x00, int8[4]},
}

local linkshell_color = struct {
    red                     ={0x01D0, uint8},
    green                   ={0x01D1, uint8},
    blue                    ={0x01D2, uint8},
}

local model = struct {
    face                    = {0x00, uint16},
    head                    = {0x02, uint16},
    body                    = {0x04, uint16},
    hands                   = {0x06, uint16},
    legs                    = {0x08, uint16},
    feet                    = {0x0A, uint16},
    main                    = {0x0C, uint16},
    ranged                  = {0x0E, uint16},
}

types.misc2_graphics = struct {
    '894E188B15????????33FF6A24893D*',
    render                  = {0x000, ptr(render)},
    footstep_effects        = {0x174, bool},
    clipping_plane_entity   = {0x1AC, float},
    clipping_plane_map      = {0x1BC, float},
    aspect_ratio_option     = {0x2EC, uint32},
    animation_framerate     = {0x304, uint32},
}

types.volumes = struct {
    '33DBF3AB6A10881D????????C705*',
    menu                    = {0x1C, float},
    footsteps               = {0x20, float},
}

types.auto_disconnect = struct {
    '6A00E8????????8B44240883C40485C07505A3*????????A3',
    enabled                 = {0x00, bool},
    last_active_time        = {0x04, uint32}, -- in ms, unknown offset
    timeout_time            = {0x08, uint32}, -- in ms
    active                  = {0x10, bool},
}

types.gamma_adjustment = struct {
    '83EC205355568BF18B0D**',
    red                     = {0x7F8, float},
    green                   = {0x7FC, float},
    blue                    = {0x800, float},
}



types.entity_array = struct {
    '8B560C8B042A8B0485',
    _unknown_0               ={0x00, int8[0x04]},
    point                    ={0x04, point},
    _unknown_10              ={0x10, int8[0x08]},
    heading                  ={0x018, float},
    _unknown_1C              ={0x1C, int8[0x04]},
    _unknown_20              ={0x20, int8[0x04]},
    point2                   ={0x024, point},
    _unknown_30              ={0x30, int8[0x08]},
    heading2                 ={0x038, float},
    _unknown_3C              ={0x3C, int8[0x04]},
    _unknown_40              ={0x40, int8[0x04]},
    point3                   ={0x044, point},
    _unknown_50              ={0x50, int8[0x4]},
    move_point               ={0x054, point},
    _unknown_60              ={0x60, int8[0x14]},
    index                    ={0x074, uint32},
    name                     ={0x07C, int8[0x18]},
    _unknown_94              ={0x94, uint32},
    movement_speed           ={0x098, float},
    movement_speed_base      ={0x09C, float},
    _unknown_A4              ={0xA4, uint32},
    _unknown_A8              ={0xA8, uint32},
    npc_talking              ={0x0AC, uint32},
    _unknown_B0              ={0xB0, uint8[0x28]},
    distance                 ={0x0D8, float},
    _unknown_DC              ={0xDC, uint32},
    _unknown_E0              ={0xE0, uint32},
    heading3                 ={0x0E4, float},
    owner                    ={0x0E8, uint32},
    hp_percent               ={0x0EC, uint8},
    _unknown_F1              ={0x0EDF, uint8},
    target_type              ={0x0EE0, uint8},
    race                     ={0x0EF, uint8},
    _unknown_F0              ={0xF0, uint8[0x0C]},
    model                    ={0x0FC, model},
    _unknown_10E             ={0x10E, uint16},
    _unknown_110             ={0x110, uint32},
    _unknown_114             ={0x114, int8[0x08]},
    freeze                   ={0x011C, bool},
    _unknown_11D             ={0x11D, uint8},
    _unknown_11E             ={0x11E, uint8},
    flags                    ={0x0120, uint32[0x06]},
    _unknown_138             ={0x138, uint8[0x06]},
    npc_speech_loop          ={0x013E, uint16},
    npc_speech_frame         ={0x0140, uint16},
    _unknown_142             ={0x142, uint8[0x16]},
    _duplicate_movement_speed={0x0158, float},
    npc_walk_pos_1           ={0x015C, uint16},
    npc_walk_pos_2           ={0x015E, uint16},
    npc_walk_mode            ={0x0160, uint16},
    _unknown_162             ={0x0162, uint16},
    _unknown_164             ={0x0164, int8[4]},
    status                   ={0x0168, uint32},
    status_svr               ={0x016C, uint32},
    _unknown_170             ={0x0170, int8[0x0C]},
    _unknown_184             ={0x0184, uint8[0x08]},
    claim_id                 ={0x0184, uint32},
    _unknown_188             ={0x0188, uint8[0x04]},
    animation                ={0x018C, animation[0x0A]},
    animation_time           ={0x01B4, uint16},
    animation_step           ={0x01B6, uint16},
    _unknown_1B8             ={0x01B8, uint16},
    _unknown_1BA             ={0x01BA, uint16},
    emote_id                 ={0x01BC, uint16},
    _unknown_1BE             ={0x01BE, uint16},
    emote_name               ={0x01C0, int8[0x04]},
    _unknown_1C4             ={0x01C4, uint8[0x08]},
    spawn_type               ={0x01CC, uint8},
    _unknown_1CD             ={0x01CD, uint8},
    _unknown_1CE             ={0x01CE, uint16},
    linkshell_color          ={0x01D0, linkshell_color},
    _unknown_1D3             ={0x01D3, uint8},
    _unknown_1D4             ={0x01D4, uint8},
    _unknown_1D5             ={0x01D5, uint8},
    campaign_mode            ={0x01D6, uint8},
    _unknown_1D7             ={0x01D7, uint8},
    fishing_timer            ={0x01D8, uint32},
    _unknown_1DC             ={0x01DC, uint8[0x18]},
    target_index             ={0x01F4, uint16},
    pet_index                ={0x01F6, uint16},
    _unknown_1F8             ={0x01F8, uint8[0x08]},
    model_scale              ={0x0200, float},
    model_size               ={0x0204, float},
    _unknown_208             ={0x0208, uint8[0x94]},
    fellow_index             ={0x029C, uint16},
    owner_index              ={0x029E, uint16},
    pets_owners_index        ={0x02A0, uint16},
}


return types
