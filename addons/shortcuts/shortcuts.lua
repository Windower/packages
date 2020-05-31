local client_data = require('client_data')
local command = require('core.command')
local entities = require('entities')
local enumerable = require('enumerable')
local ffi = require('ffi')
local list = require('list')
local packet = require('packet')
local resources = require('resources')
local string = require('string.ext')
local struct = require('struct')
local target = require('target')

local target_flags = require('client_data.types.target_flags')

local action_map = {}
local client_data_items = client_data.items

local string_normalize = string.normalize

local string_byte = string.byte
local string_sub = string.sub

local roman_literal_map = {
    [string_byte('I')] = 1,
    [string_byte('V')] = 5,
    [string_byte('X')] = 10,
    [string_byte('L')] = 50,
    [string_byte('C')] = 100,
    [string_byte('D')] = 500,
    [string_byte('M')] = 1000,
}

local parse_roman = function(name)
    local index = #name
    local total = 0
    local last = 0
    while index > 0 do
        local byte = string_byte(name, index, index)
        if byte == 0x20 then
            return string_sub(name, 1, index) .. tostring(total)
        end

        local value = roman_literal_map[byte]
        if value == nil then
            return nil
        end

        if value < last then
            total = total - value
        else
            total = total + value
        end

        last = value
        index = index - 1
    end
end

local add_single = function(name, entry)
    local normalized = string_normalize(name)
    local entries = action_map[normalized]
    if entries == nil then
        entries = {}
        action_map[normalized] = entries
    end

    entries[#entries + 1] = entry
end

local add_map = function(map)
    for name, entry in pairs(map) do
        add_single(name, entry)
    end
end

local entry_categories = {
    item = 1,
    spell = 2,
    job_ability = 3,
    weapon_skill = 4,
}

local make_entry
do
    local ffi_copy = ffi.copy
    local struct_new = struct.new

    local entry_ftype = struct.struct({
        category        = {struct.int32},
        id              = {struct.int32},
        targets         = {target_flags},
        self_only       = {struct.bool},
    })

    local targets_buffer = ffi.new('uint8_t[1]')

    make_entry = function(category, id, targets)
        local entry = struct_new(entry_ftype)

        entry.category = category
        entry.id = id
        if type(targets) == 'number' then
            targets_buffer[0] = targets
            ffi_copy(entry.targets, targets_buffer, 1)
            entry.self_only = targets == 1
        else
            entry.targets = targets
            ffi_copy(targets_buffer, targets, 1)
            entry.self_only = targets_buffer[0] == 1
        end

        return entry
    end
end

local read_items
do
    local map_item = function(item)
        local name = item.name
        if name == '.' then
            return
        end

        local entry = make_entry(entry_categories.item, item.id, item.valid_targets)

        local full_name = item.full_name

        local map = {}
        map[name] = entry
        map[full_name] = entry

        local arabic = parse_roman(name)
        if arabic then
            map[arabic] = entry
        end
        local full_arabic = parse_roman(full_name)
        if full_arabic then
            map[full_arabic] = entry
        end

        add_map(map)
    end

    read_items = function()
        for id = 0x1000, 0x1FFF do
            map_item(client_data_items[id])
        end

        for id = 0x2800, 0x59FF do
            local item = client_data_items[id]
            if item.activation_time > 0 then
                map_item(item)
            end
        end
    end
end

-- read_items()

do
    local categories = {
        [entry_categories.spell] = resources.spells,
        [entry_categories.job_ability] = resources.job_abilities,
        [entry_categories.weapon_skill] = resources.weapon_skills,
    }

    for category, resource in pairs(categories) do
        for id = 0x0000, 0x03FF do
            local action = resource[id]
            if action ~= nil and not action.unlearnable then
                local entry = make_entry(category, id, action.targets)

                local name = action.name
                add_single(string_normalize(name), entry)
                local arabic = parse_roman(name)
                if arabic then
                    add_single(string_normalize(arabic), entry)
                end
            end
        end
    end
end

local parse_targets = function(entry, target_string)
    if entry.category == 'item' then
        return
    end

    if not target_string then
        if entry.self_only then
            return target.me
        end

        return target.t
    end

    if target_string:starts_with('<') and target_string:ends_with('>') then
        return target[target_string:sub(2, -2)]
    end

    local candidates = list()
    for _, entity in pairs(entities.pcs) do
        if entity ~= nil and entity.spawned and entity.name:starts_with(target_string) then
            candidates:add(entity)
        end
    end
    return unpack(candidates)
end

local get_target
do
    get_target = function(targets, ...)
        local dead = targets.dead
        for i = 1, select('#', ...) do
            local candidate = select(i, ...)
            if candidate ~= nil and candidate.flags.dead == dead then
                local entity_type = candidate.entity_type
                if targets.player and entity_type.player
                or targets.enemy and entity_type.enemy
                or targets.party and entity_type.party
                or targets.pc and entity_type.pc
                or targets.npc and entity_type.npc
                or targets.object and entity_type.object
                or targets.pet and candidate.owner_index == target.me.index then
                    return candidate
                end
            end
        end

        return nil
    end
end

local execute_command
do
    local prefixes = {
        [entry_categories.spell] = 'ma',
        [entry_categories.job_ability] = 'ja',
        [entry_categories.weapon_skill] = 'ws',
        [entry_categories.item] = 'item',
    }

    local lookups = {
        [entry_categories.spell] = resources.spells,
        [entry_categories.job_ability] = resources.job_abilities,
        [entry_categories.weapon_skill] = resources.weapon_skills,
        [entry_categories.item] = resources.items,
    }

    execute_command = function(entry, target)
        local category = entry.category
        command.input('/' .. prefixes[category] .. ' "' .. lookups[category][entry.id].name .. '" ' .. tostring(target.id), 'client')
    end
end

local process_command = function(command, target_string)
    local entries = action_map[command:normalize()]
    if entries == nil then
        return false
    end

    for i = 1, #entries do
        local entry = entries[i]
        local target_entity = get_target(entry.targets, parse_targets(entry, target_string))
        if target_entity ~= nil then
            execute_command(entry, target_entity)
            return true
        end
    end

    return false
end

command.core.unknown_command:register(function(_, text, handled)
    if handled.set then
        return
    end

    local tokens = enumerable.to_list(text:split(' '))

    if #tokens > 1 and process_command((' '):join(tokens:skip_last(1)), tokens[-1]) or process_command(text) then
        handled.set = true
    end
end)

--[[
Copyright © 2020, Windower Dev Team
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
