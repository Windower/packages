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

local npc_name = string(0x18)
local fourcc = string(0x04)

local types = {}

local render = struct {
    framerate_divisor       = {0x030, uint32},
    aspect_ratio            = {0x2F0, float},
}

local world_coord = struct {
    x                       = {0x0, float},
    z                       = {0x4, float},
    y                       = {0x8, float}, 
    w                       = {0xC, float},
}

local animation = struct {
    value                   = {0x0, fourcc},
}

local linkshell_color = struct {
    red                     = {0x0, uint8},
    green                   = {0x1, uint8},
    blue                    = {0x2, uint8},
}

local model = struct {
    head                    = {0x0, uint16},
    body                    = {0x2, uint16},
    hands                   = {0x4, uint16},
    legs                    = {0x6, uint16},
    feet                    = {0x8, uint16},
    main                    = {0xA, uint16},
    ranged                  = {0xC, uint16},
}

types.misc2_graphics = struct {
    {'894E188B15????????33FF6A24893D*'},
    render                  = {0x000, ptr(render)},
    footstep_effects        = {0x174, bool},
    clipping_plane_entity   = {0x1AC, float},
    clipping_plane_map      = {0x1BC, float},
    aspect_ratio_option     = {0x2EC, uint32},
    animation_framerate     = {0x304, uint32},
}

types.volumes = struct {
    {'33DBF3AB6A10881D????????C705*'},
    menu                    = {0x1C, float},
    footsteps               = {0x20, float},
}

types.auto_disconnect = struct {
    {'6A00E8????????8B44240883C40485C07505A3*'},
    enabled                 = {0x00, bool},
    last_active_time        = {0x04, uint32}, -- in ms, unknown offset
    timeout_time            = {0x08, uint32}, -- in ms
    active                  = {0x10, bool},
}

types.gamma_adjustment = struct {
    {'83EC205355568BF18B0D*', static_offsets = {0}},
    red                     = {0x7F8, float},
    green                   = {0x7FC, float},
    blue                    = {0x800, float},
    _dupe_red               = {0x804, float},
    _dupe_green             = {0x808, float},
    _dupe_blue              = {0x80C, float},
}

types.entity_array = struct {
    {'8B560C8B042A8B0485*'},
    pos_display              = {0x004, world_coord},
    heading                  = {0x018, float}, -- E=0  N=+pi/2   W=+/-pi S=-pi/2
    pos                      = {0x024, world_coord},
    _dupe_heading            = {0x038, float},
    _dupe_pos                = {0x044, world_coord},
    index                    = {0x074, uint32},
    name                     = {0x07C, npc_name},
    movement_speed           = {0x098, float},
    movement_speed_base      = {0x09C, float},
    distance                 = {0x0D8, float},
    _dupe_heading2           = {0x0E4, float},
    owner                    = {0x0E8, uint32},
    hp_percent               = {0x0EC, uint8},
    target_type              = {0x0EE, uint8}, -- 0 = PC, 1 = NPC, 2 = NPC with fixed model (including various types of books), 3 = Doors and similar objects
    race                     = {0x0EF, uint16},
    face                     = {0x0FC, uint16},
    model                    = {0x0FE, model},
    freeze                   = {0x11C, bool},
    flags                    = {0x120, uint32[0x06]},
    status                   = {0x168, uint32}, -- Is this type correct?
    claim_id                 = {0x184, uint32},
    animation                = {0x18C, animation[0x0A]},
    animation_time           = {0x1B4, uint16},
    animation_step           = {0x1B6, uint16},
    emote_id                 = {0x1BC, uint16},
    emote_name               = {0x1C0, fourcc},
    spawn_type               = {0x1CC, uint8}, -- 1 = PC, 2 = NPC, 13 = Player, 16 = Mob
    linkshell_color          = {0x1D0, linkshell_color},
    campaign_mode            = {0x1D6, bool},
    fishing_timer            = {0x1D8, uint32}, -- counts down during fishing, goes 0xFFFFFFFF after 0, time until the fish bites
    target_index             = {0x1F4, uint16},
    pet_index                = {0x1F6, uint16},
    model_scale              = {0x200, float},
    model_size               = {0x204, float},
    fellow_index             = {0x29C, uint16},
    owner_index              = {0x29E, uint16},
    -- TODO: Verify
    -- npc_talking              = {0x0AC, uint32},
    -- pos_move                 = {0x054, world_coord}
    -- status_server            = {0x16C, uint32},
    -- pets_owners_index        = {0x2A0, uint16},
    -- npc_speech_loop          = {0x13E, uint16},
    -- npc_speech_frame         = {0x140, uint16},
    -- npc_walk_pos_1           = {0x15C, uint16},
    -- npc_walk_pos_2           = {0x15E, uint16},
    -- npc_walk_mode            = {0x160, uint16},
}

return types
