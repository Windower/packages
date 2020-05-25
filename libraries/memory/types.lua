local struct = setmetatable(require('struct'), {
    __call = function(t, ...)
        return t.struct(...)
    end,
})

local array = struct.array

local tag = struct.tag
local string = struct.string
local data = struct.data
local packed_string = struct.packed_string

local int8 = struct.int8
local int16 = struct.int16
local int32 = struct.int32
local int64 = struct.int64
local uint8 = struct.uint8
local uint16 = struct.uint16
local uint32 = struct.uint32
local uint64 = struct.uint64
local float = struct.float
local double = struct.double
local bool = struct.bool

local bit = struct.bit
local boolbit = struct.boolbit

local ptr = struct.ptr

local entity_id = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local percent = tag(uint8, 'percent')
local ip = tag(uint32, 'ip')
local rgba = tag(uint8[4], 'rgba')
local zone = tag(uint16, 'zone')

local pc_name = string(0x10)
local npc_name = string(0x18)
local fourcc = string(0x04)
local chat_input_buffer = string(0x97)

local vector_3f = struct({
    x                       = {0x0, float},
    z                       = {0x4, float},
    y                       = {0x8, float},
})

local vector_4f = struct({
    x                       = {0x0, float},
    z                       = {0x4, float},
    y                       = {0x8, float},
    w                       = {0xC, float},
})

local world_coord = tag(vector_4f, 'world_coord')

local matrix = float[4][4]

local screen_coord = struct({
    x                       = {0x0, float},
    z                       = {0x4, float},
})

local render = struct({
    framerate_divisor       = {0x030, uint32},
    aspect_ratio            = {0x2F0, float},
    zoom                    = {0x2F8, float},
})

local gamma = struct({
    red                     = {0x7F8, float},
    green                   = {0x7FC, float},
    blue                    = {0x800, float},
    _dupe_red               = {0x804, float},
    _dupe_green             = {0x808, float},
    _dupe_blue              = {0x80C, float},
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

struct.declare('entity')

local display = struct({
    position                = {0x34, world_coord},
    heading                 = {0x48, float},
    entity                  = {0x70, ptr('entity')},
    name_color              = {0x78, rgba},
    linkshell_color         = {0x7C, rgba},
    _pos2                   = {0xC4, world_coord},
    _pos3                   = {0xD4, world_coord},
    _heading2               = {0xE8, float},
    _speed                  = {0xF4, float}, -- Does not seem to be actual movement speed, but related to it. Animation speed?
    moving                  = {0xF8, bool},
    walking                 = {0xFA, bool},
    frozen                  = {0xFC, bool},
    nameplate_base          = {0x678, world_coord},
})

local entity = struct({
    position_display        = {0x004, world_coord},
    rotation                = {0x014, vector_4f}, -- y: E=0  N=+pi/2   W=+/-pi S=-pi/2
    position                = {0x024, world_coord},
    _dupe_rotation          = {0x034, vector_3f},
    _unknown_1              = {0x040, data(0x04)}, -- Sometimes a single world coordinate, sometimes a pointer...
    _dupe_position          = {0x044, vector_3f}, -- Seems unused! w-coordinate is occasionally overwritten by pointer value...
    _unknown_variable       = {0x050, data(0x24)}, -- Data in here varies! Sometimes the same field is a pointer, sometimes coordinates. Seems to depend on the entity
    -- Observed constellations:
    -- Ding Bats
    --  ptr1    coord   coord   coord       -- small coordinates, ~0.01 range
    --  ptr2    ptr3    ptr4    0           -- ptr2 == _unknonw_1 - 0x35C, ptr3 == ptr1 + 0xCA0, ptr4 == ptr1 + 28A6
    --  1(float)
    -- Wild Rabbit
    --  0       0       0       0
    --  0       1       0       0
    --  1(int)
    index                   = {0x074, entity_index},
    id                      = {0x078, entity_id},
    name                    = {0x07C, npc_name},
    _unknown_ptr_1          = {0x094, ptr()},
    movement_speed          = {0x098, float},
    movement_speed_base     = {0x09C, float},
    display                 = {0x0A0, ptr(display)},
    distance                = {0x0D8, float},
    _dupe_heading2          = {0x0E4, float},
    owner                   = {0x0E8, entity_id},
    hp_percent              = {0x0EC, percent},
    target_type             = {0x0EE, uint8}, -- 0 = PC, 1 = NPC, 2 = NPC with fixed model (including various types of books), 3 = Doors and similar objects
    race_id                 = {0x0EF, uint8},
    face_model_id           = {0x0FC, uint16},
    model                   = {0x0FE, model},
    freeze                  = {0x11C, bool},
    flags                   = {0x120, struct({size = 0x18}, {
        spawned                 = {0x01, boolbit(uint8), offset=1},
        enemy                   = {0x01, boolbit(uint8), offset=5},
        hidden                  = {0x01, boolbit(uint8), offset=6},
        dead                    = {0x02, boolbit(uint8), offset=6},
        invisible               = {0x05, boolbit(uint8), offset=4},
        seeking                 = {0x06, boolbit(uint8), offset=4},
        autogroup               = {0x06, boolbit(uint8), offset=5},
        away                    = {0x06, boolbit(uint8), offset=6},
        anonymous               = {0x06, boolbit(uint8), offset=7},
        help                    = {0x07, boolbit(uint8), offset=0},
        temp_logged             = {0x07, boolbit(uint8), offset=2},
        linkshell               = {0x07, boolbit(uint8), offset=3},
        connection_lost         = {0x07, boolbit(uint8), offset=4},
        object                  = {0x08, boolbit(uint8), offset=3},
        bazaar                  = {0x09, boolbit(uint8), offset=1},
        promotion               = {0x09, boolbit(uint8), offset=3},
        promotion_2             = {0x09, boolbit(uint8), offset=4},
        gm                      = {0x09, boolbit(uint8), offset=5},
        maintenance             = {0x09, boolbit(uint8), offset=6},
        name_deletion           = {0x0C, boolbit(uint8), offset=7},
        charmed                 = {0x0D, boolbit(uint8), offset=5},
        attackable              = {0x0F, boolbit(uint8), offset=1},
        name_hidden             = {0x10, boolbit(uint8), offset=7},
        mentor                  = {0x11, boolbit(uint8), offset=4},
        new_player              = {0x11, boolbit(uint8), offset=5},
        trial_account           = {0x11, boolbit(uint8), offset=6},
        visible_distance        = {0x11, boolbit(uint8), offset=7},
        transparent             = {0x12, boolbit(uint8), offset=3},
        hp_cloak                = {0x12, boolbit(uint8), offset=4},
        level_sync              = {0x12, boolbit(uint8), offset=7},
    })},
    _unkonwn_ptr_2          = {0x150, ptr()}, -- Sometimes same as _unknown_1
    _unknown_float_1        = {0x158, float}, -- Always 4?
    _unknown_short_1        = {0x15C, uint16}, -- Flags?
    _unknown_short_2        = {0x15E, uint16}, -- Duplicate of _unknown_short_1
    state_id                = {0x168, uint32}, -- Is this type correct?
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
    heading                 = {
        get = function(data) return data.rotation.z end,
        set = function(data, value) data.rotation.z = value end,
    },
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

local target_array_entry = struct({size = 0x28}, {
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

local party_member = struct({size = 0x7C}, {
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
})

local chat_menu_entry = struct({
    _ptr_chat_input_this    = {0x00, ptr()}, -- This pointer to the parent struct of the chat input struct
    display                 = {0x04, ptr()}, -- Pointer to a null-terminated string for display in the menu
    length_display          = {0x08, uint16}, -- Length (in bytes) of the display buffer associated with this entry
    internal                = {0x0C, ptr()}, -- Pointer to a null-terminated string which will be copied to the internal buffer
    length_internal         = {0x10, uint16}, -- Length (in bytes) of the internal buffer associated with this entry
    auto_translate          = {0x14, string(0x04)}, -- Auto-translate code, 0 if the phrase is a regular string
})

local entity_string = struct({
    name                    = {0x00, string(0x18)},
    id                      = {0x1C, uint32},
})

local map_entry = struct({
    zone_id                 = {0x00, int16},
    map_id                  = {0x02, int8},
    count                   = {0x03, int8},
    dat_offset              = {0x04, bit(uint8, 4), offset=0}, -- [0] = 5312, [1] = 53295
    key_item_offset         = {0x04, bit(uint8, 4), offset=4}, -- [0] = 384, [1] = 1855, [2] = 2301
    scale                   = {0x05, int8},
    key_item_index          = {0x06, int8},
    dat_index               = {0x08, int16},
    offset_x                = {0x0A, int16},
    offset_y                = {0x0C, int16},
})

local types = {}

types.language_filter = struct({signature = '84C0750333C0C38B0D', offsets = {0x20}}, {
    disabled                = {0x04, bool},
})

types.graphics = struct({signature = '83EC205355568BF18B0D'}, {
    gamma                   = {0x000, ptr(gamma)},
    render                  = {0x28C, ptr(render)},
    footstep_effects        = {0x400, bool},
    clipping_plane_entity   = {0x438, float},
    clipping_plane_map      = {0x448, float},
    aspect_ratio_option     = {0x578, uint32},
    animation_framerate     = {0x590, uint32},
    view_matrix             = {0xBB8, matrix},
    projection_matrix       = {0xDF8, matrix},
})

types.volumes = struct({signature = '33DBF3AB6A10881D????????C705'}, {
    menu                    = {0x1C, float},
    footsteps               = {0x20, float},
})

types.auto_disconnect = struct({signature = '6A00E8????????8B44240883C40485C07505A3'}, {
    enabled                 = {0x00, bool},
    last_active_time        = {0x04, uint32}, -- in ms, unknown offset
    timeout_time            = {0x08, uint32}, -- in ms
    active                  = {0x10, bool},
})

types.entities = array({signature = '8B560C8B042A8B0485'}, ptr(entity), 0x900)

types.account_info = struct({signature = '538B5C240856578BFB83C9FF33C053F2AEA1'}, {
    version                 = {0x248, string(0x10)},
    ip                      = {0x260, ip},
    port                    = {0x26C, uint16},
    id                      = {0x314, entity_id},
    name                    = {0x318, pc_name},
    server_id               = {0x390, int16},
})

types.target = struct({signature = '53568BF18B480433DB3BCB75065E33C05B59C38B0D&', offsets = {0x18, 0x00}}, {
    window                  = {0x08, ptr()},
    name                    = {0x14, npc_name},
    entity                  = {0x48, ptr(entity)},
    id                      = {0x60, entity_id},
    hp_percent              = {0x64, uint8},
})

types.target_array = struct({signature = '53568BF18B480433DB3BCB75065E33C05B59C38B0D&', offsets = {0x18, 0x2F0}}, {
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

types.party = struct({signature = '6A0E8BCE89442414E8????????8B0D'}, {
    members                 = {0x2C, party_member[18]},
})

types.tell_history = struct({signature = '8B0D????????85C9740F8B15'}, {
    recipient_count         = {0x004, uint16},
    recipients              = {0x008, pc_name[8]}, -- last 8 /tell recipients
    _dupe_recipient_count   = {0x088, uint16},
    _dupe_recipients        = {0x08C, pc_name[8]},
    chatlog_open            = {0x10D, bool},
    chatmode_tell_target    = {0x10E, pc_name}, -- Only set when /chatmode tell
    senders                 = {0x11E, pc_name[8]},
})

types.chat_input = struct({signature = '3BCB74148B01FF502084C0740B8B0D', offsets = {0x00}}, {
    temporary_buffer        = {0x7EDC, chat_input_buffer},
    history                 = {0x7F73, chat_input_buffer[9]},
    temporary_length        = {0x84C4, uint8},
    history_lengths         = {0x84C8, uint8[9]},
    history_length          = {0x84EC, uint8},
    history_index           = {0x84F0, uint8},
    internal                = {0x84F4, chat_input_buffer},
    length_internal         = {0x86B8, uint8},
    stripped                = {0x86BC, chat_input_buffer},
    length_stripped         = {0x8880, uint8},
    length_internal_max     = {0x8884, uint8},
    position_internal       = {0x8888, uint8},
    update_history          = {0x8AA8, bool},
    tab_menu_open           = {0x8C81, bool},
    menu_selection          = {0x8C84, uint8},
    menu_entries            = {0x8C88, chat_menu_entry[0x3FC]},
    menu_length             = {0xEC28, uint8},
    move_counter            = {0xEC30, uint8},
    display                 = {0xEC34, chat_input_buffer},
    open                    = {0xEF22, bool},
})

types.follow = struct({signature = '8BCFE8????FFFF8B0D????????E8????????8BE885ED750CB9'}, {
    target_index            = {0x04, entity_index},
    target_id               = {0x08, entity_id},
    postion                 = {0x0C, world_coord},
    follow_index            = {0x20, entity_index},
    follow_id               = {0x24, entity_id}, -- Once set will overwrite pos with directional values
    first_person_view       = {0x28, bool},
    auto_run                = {0x29, bool},
})

types.string_tables = struct({signature = '8B81????0000F6C402750532C0C20400A0'}, {
    skills                  = {0x10, ptr()},
    elements                = {0x14, ptr()},
    entities                = {0x18, ptr(entity_string)},
    emotes                  = {0x1C, ptr()},
    actions                 = {0x20, ptr()},
    status_effects          = {0x24, ptr()},
    gameplay                = {0x28, ptr()},
    abilities               = {0x34, ptr()},
    unity                   = {0x38, ptr()},
    zone                    = {0x3C, ptr()},
})

types.action_strings = struct({signature = '7406B8????????C38B4424046A006A0050B9'}, {
    abilities               = {0x014, ptr()},
    mounts                  = {0x094, ptr()},
    spells                  = {0x9B4, ptr()},
})

types.status_effect_strings = struct({signature = '8A46055E3C0273188B0D', offsets = {0x00}}, {
    d_msg                   = {0x04, ptr()},
})

types.weather_strings = struct({signature = 'C333C9668B08518B0D', offsets = {0x148}}, {
    d_msg                   = {0x00, ptr()},
})

types.d_msg_table = struct({signature = '85C0752B5F5EC38B0CF5'}, {
    str0                    = {0x00, ptr(ptr())}, -- [1] = Failed to read data. [2] = Checking the size of the files to download and
    str1                    = {0x08, ptr(ptr())}, -- [1] = Error code: FFXI-%04d [2] = Could not connect to lobby server.
    str2                    = {0x10, ptr(ptr())}, -- nullptr
    str3                    = {0x18, ptr(ptr())}, -- [1] = You are currently not in a party. [2] = This region is not under any country's control.
    str4                    = {0x20, ptr(ptr())}, -- nullptr
    str5                    = {0x28, ptr(ptr())}, -- [1] = Race [2] = Job
    str6                    = {0x30, ptr(ptr())}, -- [1] = Shout [2] = Tell
    str7                    = {0x38, ptr(ptr())}, -- [1] = Activate Linkshell item and participate in its chat channel. [2] = Deactivate Linkshell item and quit its chat channel.
    str8                    = {0x40, ptr(ptr())}, -- [1] = Region Info [2] = Items
    str9                    = {0x48, ptr(ptr())}, -- [1] = All [2] All
    regions                 = {0x50, ptr(ptr())},
    zones                   = {0x58, ptr(ptr())},
    zone_autotranslates     = {0x60, ptr(ptr())},
    servers                 = {0x68, ptr(ptr())},
    jobs                    = {0x70, ptr(ptr())},
    days                    = {0x78, ptr(ptr())},
    directions              = {0x80, ptr(ptr())},
    moon_phases             = {0x88, ptr(ptr())},
    _dupe_jobs              = {0x90, ptr(ptr())},
    job_abbreviations       = {0x98, ptr(ptr())},
    _dupe_zones             = {0xA0, ptr(ptr())},
    zone_search_names       = {0xA8, ptr(ptr())},
    races                   = {0xB0, ptr(ptr())},
    str23                   = {0xB8, ptr(ptr())}, -- nullptr
    equipment_slots         = {0xC0, ptr(ptr())},
    _dupe_equipment_slots   = {0xC8, ptr(ptr())},
    einherjar_chambers      = {0xD0, ptr(ptr())},
    str27                   = {0xD8, ptr(ptr())}, -- [1] = Objectives [2] = Get grinding!
})

types.music = struct({signature = '668B490625FFFF000066C705????????FFFF66890C45'}, {
    day                     = {0x0, uint16},
    night                   = {0x2, uint16},
    solo_combat             = {0x4, uint16},
    party_combat            = {0x6, uint16},
    mount                   = {0x8, uint16},
    knockout                = {0xA, uint16},
    mog_house               = {0xC, uint16},
    fishing                 = {0xE, uint16},
})

types.map_table = struct({signature = '8A5424188B7424148B7C2410B9&'}, {
    ptr = {0x00, ptr(map_entry)},
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
