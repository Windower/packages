local struct = require('struct')

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

local string = struct.string

local struct = struct.struct

local string_table = struct({
    count           = {0x00, uint32},
    entries         = {0x04, struct({
        offset      = {0x00, uint32},
        type        = {0x04, uint32},
    })[5]},
})

local item_struct
do
    local icon_descriptor = {0x280, uint8[0x980]}
    item_struct = function(string_offset, fields)
        fields._strings = {string_offset, string_table}
        fields.icon = icon_descriptor
        return struct(fields)
    end
end

local types = {}

types.general_item = item_struct(0x18, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    element         = {0x0E, uint16},
    storage         = {0x10, uint16},
    _item_ref_id    = {0x12, uint16},
    _unknown1       = {0x14, uint16},
    attachment_id   = {0x16, uint16},
})

types.usable_item = item_struct(0x1C, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    activation_time = {0x0E, uint16},
    _item_ref_id    = {0x10, uint16},
    _unknown2       = {0x12, uint8},
    action_type     = {0x13, uint8},
    action_id       = {0x14, uint16},
    aoe_range       = {0x16, uint8},
    aoe             = {0x17, bool},
    aoe_targets     = {0x18, uint8},
})

types.automaton_item = item_struct(0x18, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    automaton_slot  = {0x0E, uint16},
    charge          = {0x10, struct({
        fire        = {0x00, bit(uint32, 4), offset = 0x00},
        ice         = {0x00, bit(uint32, 4), offset = 0x04},
        wind        = {0x00, bit(uint32, 4), offset = 0x08},
        earth       = {0x00, bit(uint32, 4), offset = 0x0C},
        lightning   = {0x00, bit(uint32, 4), offset = 0x10},
        water       = {0x00, bit(uint32, 4), offset = 0x14},
        light       = {0x00, bit(uint32, 4), offset = 0x18},
        dark        = {0x00, bit(uint32, 4), offset = 0x1C},
    })},
    _unknown3       = {0x14, uint32},
})

types.armor_item = item_struct(0x2C, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    level           = {0x0E, uint16},
    equipment_slots = {0x10, uint16},
    races           = {0x12, uint16},
    jobs            = {0x14, uint32},
    superior_level  = {0x18, uint16},
    shield_type     = {0x1A, uint16},
    max_charges     = {0x1C, uint8},
    cast_time       = {0x1D, uint8},
    use_delay       = {0x1E, uint16},
    reuse_delay     = {0x20, uint32},
    _item_ref_id    = {0x24, uint16},
    item_level      = {0x26, uint8},
    _augmentable    = {0x27, bool},
    aoe_modifier    = {0x28, uint8},
    aoe_range       = {0x29, uint8},
    aoe             = {0x2A, bool},
    aoe_targets     = {0x2B, uint8},
})

types.weapon_item = item_struct(0x38, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    level           = {0x0E, uint16},
    equipment_slots = {0x10, uint16},
    races           = {0x12, uint16},
    jobs            = {0x14, uint32},
    superior_level  = {0x18, uint16},
    damage          = {0x1C, uint16},
    delay           = {0x1E, uint16},
    dps             = {0x20, uint16},
    skill           = {0x22, uint8},
    animation       = {0x24, uint32},
    max_charges     = {0x28, uint8},
    cast_time       = {0x29, uint8},
    use_delay       = {0x2A, uint16},
    reuse_delay     = {0x2C, uint32},
    _item_ref_id    = {0x30, uint16},
    item_level      = {0x32, uint8},
    _augmentable    = {0x33, bool},
    aoe_modifier    = {0x34, uint8},
    aoe_range       = {0x35, uint8},
    aoe             = {0x36, bool},
    targets         = {0x37, uint8},
})

types.maze_tabula_item = item_struct(0x54, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    tabula_layout   = {0x14, int8[25]},
})

types.maze_voucher_item = item_struct(0x54, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    _unknown5       = {0x14, uint8[15]},
})

types.maze_rune_item = item_struct(0x54, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    element         = {0x14, int8},
    shape           = {0x15, uint8},
})

types.basic_item = item_struct(0x54, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
})

types.instinct_item = item_struct(0x28, {
    id              = {0x00, uint16},
    _unknown6       = {0x04, uint32},
    _unknown7       = {0x08, uint16},
    instinct_id     = {0x0A, uint16},
    _unknown8       = {0x0E, uint16},
    _unknown9       = {0x12, uint16},
    faculty_points  = {0x18, uint32},
})

types.monipulator_item = item_struct(0x70, {
    id              = {0x00, uint16},
    monipulator_id  = {0x04, uint16},
    name            = {0x06, string(32)},
    family          = {0x26, uint16},
    species         = {0x28, uint16},
    sort_value      = {0x2A, uint16},
    _unknown10      = {0x2C, uint16},
    size            = {0x2E, uint16},
    abilities       = {0x30, struct({
        id          = {0x00, uint16},
        level       = {0x02, uint8},
        _unknown    = {0x03, uint8},
    })[16]},
})

types.gil_item = item_struct(0x10, {
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    _unknown11      = {0x07, uint8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
})

types.type_map = {
    {first = 0x0000, last = 0x0FFF, base = 0x0000, en = 0x0049, ja = 0x0004, type = types.general_item},
    {first = 0x1000, last = 0x1FFF, base = 0x1000, en = 0x004A, ja = 0x0005, type = types.usable_item},
    {first = 0x2000, last = 0x21FF, base = 0x2000, en = 0x004D, ja = 0x0008, type = types.automaton_item},
    {first = 0x2200, last = 0x27FF, base = 0x2200, en = 0xD977, ja = 0xD8FF, type = types.general_item},
    {first = 0x2800, last = 0x3FFF, base = 0x2800, en = 0x004C, ja = 0x0007, type = types.armor_item},
    {first = 0x4000, last = 0x59FF, base = 0x4000, en = 0x004B, ja = 0x0006, type = types.weapon_item},
    {first = 0x5A00, last = 0x6FFF, base = 0x5A00, en = 0xD974, ja = 0xD8FC, type = types.armor_item},
    {first = 0x7000, last = 0x703F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = types.maze_tabula_item},
    {first = 0x7040, last = 0x707F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = types.maze_voucher_item},
    {first = 0x7080, last = 0x727F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = types.maze_rune_item},
    {first = 0x7280, last = 0x73FF, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = types.basic_item},
    {first = 0x7400, last = 0x77FF, base = 0x7400, en = 0xD976, ja = 0xD8FE, type = types.instinct_item},
    {first = 0xF000, last = 0xF1FF, base = 0xF000, en = 0xD975, ja = 0xD8FD, type = types.monipulator_item},
    {first = 0xFFFF, last = 0xFFFF, base = 0xFFFF, en = 0x005B, ja = 0x0009, type = types.gil_item},
}

return types

--[[
Copyright © 2019, Windower Dev Team
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
