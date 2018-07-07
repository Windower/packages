local structs = require('structs')

local struct = function(info, data, size)
    if data == nil then
        return structs.struct(info)
    end

    if type(data) == 'number' then
        structs.struct(info, nil, data)
    end

    return structs.struct(data, info)
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
local packed_string = structs.packed_string

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

local bit = structs.bit
local boolbit = structs.boolbit

local ptr = structs.ptr

local entity_id = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local percent = tag(uint8, 'percent')
local ip = tag(uint32, 'ip')
local rgba = tag(uint8[4], 'rgba')
local zone = tag(uint16, 'zone')

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

local screen_coord = struct({
    x                       = {0x0, float},
    z                       = {0x4, float},
})

local linkshell_color = struct({
    red                     = {0x0, uint8},
    green                   = {0x1, uint8},
    blue                    = {0x2, uint8},
})

local model = struct({
    head_model_id           = {0x0, uint16},
    body_model_id           = {0x2, uint16},
    hands_model_id          = {0x4, uint16},
    legs_model_id           = {0x6, uint16},
    feet_model_id           = {0x8, uint16},
    main_model_id           = {0xA, uint16},
    sub_model_id            = {0xC, uint16},
    range_model_id          = {0xE, uint16},
})

local display = struct({
    pos                     = {0x34, world_coord},
    heading                 = {0x48, float},
    entity                  = {0x70, ptr(entity)}, -- This will currently not work since `entity` is nil here... not a trivial problem
    name_color              = {0x78, rgba},
    linkshell_color         = {0x7C, rgba},
    _pos2                   = {0xC4, world_coord},
    _pos3                   = {0xD4, world_coord},
    _heading2               = {0xE8, float},
    _speed                  = {0xF4, float}, -- Does not seem to be actual movement speed, but related to it. Animation speed?
    moving                  = {0xF8, bool},
    walking                 = {0xFA, bool},
    frozen                  = {0xFC, bool},
})

local entity = struct({
    position_display        = {0x004, world_coord},
    heading                 = {0x018, float}, -- E=0  N=+pi/2   W=+/-pi S=-pi/2
    position                = {0x024, world_coord},
    _dupe_heading           = {0x038, float},
    _dupe_position          = {0x044, world_coord},
    index                   = {0x074, entity_index},
    id                      = {0x078, entity_id},
    name                    = {0x07C, npc_name},
    movement_speed          = {0x098, float},
    movement_speed_base     = {0x09C, float},
    display                 = {0x0A0, ptr(display)},
    distance                = {0x0D8, float},
    _dupe_heading2          = {0x0E4, float},
    owner                   = {0x0E8, entity_id},
    hp_percent              = {0x0EC, percent},
    target_type             = {0x0EE, uint8}, -- 0 = PC, 1 = NPC, 2 = NPC with fixed model (including various types of books), 3 = Doors and similar objects
    race_id                 = {0x0EF, uint16},
    face_model_id           = {0x0FC, uint16},
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

local target_array_entry = struct({
    index                   = {0x00, entity_index},
    id                      = {0x04, entity_id},
    entity                  = {0x08, ptr(entity)},
    display                 = {0x0C, ptr(display)},
    arrow_pos               = {0x10, world_coord},
    active                  = {0x20, bool},
    arrow_active            = {0x22, bool},
    checksum                = {0x24, uint16},
})

local alliance_info = struct({
    alliance_leader_id      = {0x00, entity_id},
    party_1_leader_id       = {0x04, entity_id},
    party_2_leader_id       = {0x08, entity_id},
    party_3_leader_id       = {0x0C, entity_id},
    party_1_index           = {0x10, uint8},
    party_2_index           = {0x11, uint8},
    party_3_index           = {0x12, uint8},
    party_1_count           = {0x13, uint8},
    party_2_count           = {0x14, uint8},
    party_3_count           = {0x15, uint8},
    st_selection            = {0x50, uint8},
    st_selection_max        = {0x63, uint8}, -- 6 for <stpt>, 18 for <stal>
    _unknown_5F             = {0x64, uint8}, -- Seems to be FF when in <stpt> or <stal>, otherwise 00
})

local party_member = struct({
    alliance_info           = {0x00, ptr(alliance_info)},
    name                    = {0x06, pc_name},
    id                      = {0x18, entity_id},
    index                   = {0x1C, entity_index},
    hp                      = {0x24, uint32},
    mp                      = {0x28, uint32},
    tp                      = {0x2C, uint32},
    hp_percent              = {0x30, percent},
    mp_percent              = {0x31, percent},
    zone_id                 = {0x32, zone},
    _zone_id2               = {0x34, zone},
    flags                   = {0x38, uint32},
    _id2                    = {0x74, entity_id},
    _hp_percent2            = {0x78, percent},
    _mp_percent2            = {0x79, percent},
    active                  = {0x7A, bool},
    _last                   = {0x7B, data(1)},
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

types.gamma_adjustment = struct({'83EC205355568BF18B0D', static_offsets = {0x00}}, {
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
    server_id               = {0x390, uint8},
})

types.target = struct({'53568BF18B480433DB3BCB75065E33C05B59C38B0D&', static_offsets = {0x18, 0x00}}, {
    window                  = {0x08, ptr()},
    name                    = {0x14, npc_name},
    entity                  = {0x48, ptr(entity)},
    id                      = {0x60, entity_id},
    hp_percent              = {0x64, uint8},
})

types.target_array = struct({'53568BF18B480433DB3BCB75065E33C05B59C38B0D&', static_offsets = {0x18, 0x2F0}}, {
    targets                 = {0x00, target_array_entry[2]},
    auto_target             = {0x51, bool},
    both_targets_active     = {0x52, bool},
    movement_input          = {0x57, bool}, -- True whenever character moves (or tries to move) via user input
    alliance_target_active  = {0x59, bool}, -- This includes party targeting
    target_locked           = {0x5C, boolbit(uint32), offset=0},
    sub_target_mask         = {0x60, uint32}, -- Bit mask indicating valid sub target selection
                                              --     0:  PCs/Pets/Trusts
                                              --     1:  Green NPCs/Pets/Trusts
                                              --     2:  Party members (incl. Trusts)
                                              --     3:  Alliance members (incl. Trusts)
                                              --     4:  Enemies
                                              -- Unsure about the significance of the second byte in this int
                                              --     0:  <stnpc>
                                              --     2:  <stpc>
                                              --     3:  <st>
                                              -- Changing the second byte does not seem to have an effect
                                              -- The entire int is -1 if no sub target is active
    action_target_active    = {0x6C, bool},
    action_range            = {0x6D, uint8}, -- One less than the distance in yalms (including 0xFF for self-targeting spells)
    menu_open               = {0x74, bool},
    action_category         = {0x76, uint8}, -- 1 for JA/WS, 2 for spells
    action_aoe_range        = {0x77, uint8}, -- Base range for AoE modifiers, this is not directly related to the distance drawn on the screen
                                             -- For example increased range by different instruments will not change this value for AoE songs
    action_id               = {0x78, uint16}, -- The ID of the JA, WS or spell
    action_target_id        = {0x7C, entity_id},
    focus_index             = {0x84, entity_index}, -- Only set when the target exists in the entity array
    focus_id                = {0x88, entity_id}, -- Always set, even if target not in zone
    mouse_pos               = {0x8C, screen_coord},
    last_st_name            = {0x9C, npc_name},
    last_st_index           = {0xB8, entity_index},
    last_st_id              = {0xB8, entity_id},
    _unknown_ptr1           = {0xC0, ptr()}, -- Something related to LastST, address seems to differ for PC and NPC
    _unknown_ptr2           = {0xC4, ptr()}, -- Something related to action target, seems there's one address for spells and one for JA/WS
    _unknown_ptr3           = {0xC8, ptr()}, -- Something related to action target, seems there's one address for spells and one for JA/WS
    _unknown_ptr4           = {0xD0, ptr()}, -- Something related to action target, seems there's one address for spells and one for JA/WS
})

types.party = struct({'6A0E8BCE89442414E8????????8B0D'}, {
    members                 = {0x2C, party_member[18]},
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
