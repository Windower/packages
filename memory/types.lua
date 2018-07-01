local structs = require('structs')

local struct = function(info, type)
    if type == nil then
        return structs.struct(info)
    end

    return structs.struct(type, info)
end

local array = function(info, type, count)
    if count == nil then
        return structs.array(info, type)
    end

    return structs.array(type, count, info)
end

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

local entity_id = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local percent = tag(uint8, 'percent')
local ip = tag(uint32, 'ip')

local pc_name = string(0x10)
local npc_name = string(0x18)
local fourcc = string(0x04)

local render = struct({
    framerate_divisor       = {0x030, uint32},
    aspect_ratio            = {0x2F0, float},
})

local world_coord = struct({
    x                       = {0x0, float},
    z                       = {0x4, float},
    y                       = {0x8, float}, 
    w                       = {0xC, float},
})

local linkshell_color = struct({
    red                     = {0x0, uint8},
    green                   = {0x1, uint8},
    blue                    = {0x2, uint8},
})

local model = struct({
    head                    = {0x0, uint16},
    body                    = {0x2, uint16},
    hands                   = {0x4, uint16},
    legs                    = {0x6, uint16},
    feet                    = {0x8, uint16},
    main                    = {0xA, uint16},
    ranged                  = {0xC, uint16},
})

local entity = struct({
    pos_display             = {0x004, world_coord},
    heading                 = {0x018, float}, -- E=0  N=+pi/2   W=+/-pi S=-pi/2
    pos                     = {0x024, world_coord},
    _dupe_heading           = {0x038, float},
    _dupe_pos               = {0x044, world_coord},
    index                   = {0x074, entity_index},
    id                      = {0x078, entity_id},
    name                    = {0x07C, npc_name},
    movement_speed          = {0x098, float},
    movement_speed_base     = {0x09C, float},
    distance                = {0x0D8, float},
    _dupe_heading2          = {0x0E4, float},
    owner                   = {0x0E8, entity_id},
    hp_percent              = {0x0EC, percent},
    target_type             = {0x0EE, uint8}, -- 0 = PC, 1 = NPC, 2 = NPC with fixed model (including various types of books), 3 = Doors and similar objects
    race                    = {0x0EF, uint16},
    face                    = {0x0FC, uint16},
    model                   = {0x0FE, model},
    freeze                  = {0x11C, bool},
    flags                   = {0x120, uint32[0x06]},
    status                  = {0x168, uint32}, -- Is this type correct?
    claim_id                = {0x184, entity_id},
    animation               = {0x18C, fourcc[0x0A]},
    animation_time          = {0x1B4, uint16},
    animation_step          = {0x1B6, uint16},
    emote_id                = {0x1BC, uint16},
    emote_name              = {0x1C0, fourcc},
    spawn_type              = {0x1CC, uint8}, -- 1 = PC, 2 = NPC, 13 = Player, 16 = Mob
    linkshell_color         = {0x1D0, linkshell_color},
    campaign_mode           = {0x1D6, bool},
    fishing_timer           = {0x1D8, uint32}, -- counts down during fishing, goes 0xFFFFFFFF after 0, time until the fish bites
    target_index            = {0x1F4, entity_index},
    pet_index               = {0x1F6, entity_index},
    model_scale             = {0x200, float},
    model_size              = {0x204, float},
    fellow_index            = {0x29C, entity_index},
    owner_index             = {0x29E, entity_index},
    -- TODO: Verify
    -- npc_talking             = {0x0AC, uint32},
    -- pos_move                = {0x054, world_coord}
    -- status_server           = {0x16C, uint32},
    -- pets_owners_index       = {0x2A0, entity_index},
    -- npc_speech_loop         = {0x13E, uint16},
    -- npc_speech_frame        = {0x140, uint16},
    -- npc_walk_pos_1          = {0x15C, uint16},
    -- npc_walk_pos_2          = {0x15E, uint16},
    -- npc_walk_mode           = {0x160, uint16},
})

local types = {}

types.misc2_graphics = struct({'894E188B15????????33FF6A24893D'}, {
    render                  = {0x000, ptr(render)},
    footstep_effects        = {0x174, bool},
    clipping_plane_entity   = {0x1AC, float},
    clipping_plane_map      = {0x1BC, float},
    aspect_ratio_option     = {0x2EC, uint32},
    animation_framerate     = {0x304, uint32},
})

types.volumes = struct({'33DBF3AB6A10881D????????C705'}, {
    menu                    = {0x1C, float},
    footsteps               = {0x20, float},
})

types.auto_disconnect = struct({'6A00E8????????8B44240883C40485C07505A3'}, {
    enabled                 = {0x00, bool},
    last_active_time        = {0x04, uint32}, -- in ms, unknown offset
    timeout_time            = {0x08, uint32}, -- in ms
    active                  = {0x10, bool},
})

types.gamma_adjustment = struct({'83EC205355568BF18B0D', static_offsets = {0}}, {
    red                     = {0x7F8, float},
    green                   = {0x7FC, float},
    blue                    = {0x800, float},
    _dupe_red               = {0x804, float},
    _dupe_green             = {0x808, float},
    _dupe_blue              = {0x80C, float},
})

types.entities = array({'8B560C8B042A8B0485'}, ptr(entity), 0x900)

types.account_info = struct({'538B5C240856578BFB83C9FF33C053F2AEA1'}, {
    version                 = {0x248, string(0x10)},
    ip                      = {0x260, ip},
    port                    = {0x26C, uint16},
    id                      = {0x314, entity_id},
    name                    = {0x318, pc_name},
    server                  = {0x390, uint8},
})

return types

--[[
Copyright © 2018, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
