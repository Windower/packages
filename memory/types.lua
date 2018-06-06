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

return types
