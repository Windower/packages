local action = require('action')
local chat = require('core.chat')
local client_data = require('client_data')
local command = require('core.command')
local entities = require('entities')
local ffi = require('ffi')
local fn = require('expression')
local list = require('list')
local resources = require('resources')
local string = require('string.ext')
local struct = require('struct')
local table = require('table')
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

local category_magic = action.category.magic
local category_job_ability = action.category.job_ability
local category_weapon_skill = action.category.weapon_skill
local category_item = action.category.item
local category_mount = action.category.mount

local category_resources = {
    [category_item] = client_data_items,
    [category_magic] = resources.spells,
    [category_job_ability] = resources.job_abilities,
    [category_weapon_skill] = resources.weapon_skills,
    [category_mount] = resources.mount,
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

do
    local map_item = function(item)
        local name = item.name
        if name == '.' then
            return
        end

        local entry = make_entry(category_item, item.id, item.valid_targets)

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

do
    local categories = {
        [category_magic] = resources.spells,
        [category_job_ability] = resources.job_abilities,
        [category_weapon_skill] = resources.weapon_skills,
        [category_mount] = resources.mounts,
    }

    for category, resource in pairs(categories) do
        for id, action_resource in pairs(resource) do
            if not action_resource.unlearnable then
                local entry = make_entry(category, id, action_resource.targets or 1)

                local name = action_resource.name
                add_single(string_normalize(name), entry)
                local arabic = parse_roman(name)
                if arabic then
                    add_single(string_normalize(arabic), entry)
                end
            end
        end
    end
end

local process_command
do
    local parse_targets
    do
        local get_default_targets = function(entry)
            if entry.self_only then
                return target.me
            end

            local targets = entry.targets
            local current_target = target.t
            if targets.player then
                if current_target ~= nil then
                    if targets.enemy and current_target.entity_flags.enemy then
                        return target.me, current_target
                    end
                    return current_target, target.me
                end

                return target.me
            end

            if current_target ~= nil then
                return current_target
            end

            error('Could not determine target.')
        end

        parse_targets = function(entry, target_string)
            if not target_string then
                return {get_default_targets(entry)}
            end

            if target_string:starts_with('<') and target_string:ends_with('>') then
                return {target[target_string:sub(2, -2)]}
            end

            local target_entity = target[target_string]
            if target_entity ~= nil then
                return {target_entity}
            end

            local name_prefix = target_string:sub(1, 1):upper() .. target_string:sub(2)

            local pcs = list()
            local alliance = list()
            local party = list()

            for _, entity in pairs(entities.pcs) do
                if entity ~= nil and entity.flags.spawned then
                    if entity.name == name_prefix then
                        return entity
                    end

                    if entity.name:starts_with(name_prefix) then
                        local entity_flags = entity.entity_flags
                        if entity_flags.party then
                            party:add(entity)
                        elseif entity_flags.alliance then
                            alliance:add(entity)
                        else
                            pcs:add(entity)
                        end
                    end
                end
            end

            for _, collection in ipairs({party, alliance, pcs}) do
                if collection:any() then
                    if collection:count() > 1 then
                        error('Provided target ambiguous for "' .. target_string .. '". Choices: ' .. (', '):join(collection:select(fn.index('name'))))
                    end

                    return {collection:first()}
                end
            end

            error('Could not determine target for "' .. target_string .. '".')
        end
    end

    local get_target
    do
        get_target = function(targets, ...)
            for i = 1, select('#', ...) do
                local candidate = select(i, ...)
                local entity_flags = candidate.entity_flags
                if targets.player and entity_flags.player
                or targets.enemy and entity_flags.enemy
                or targets.party and entity_flags.party
                or targets.pc and entity_flags.pc
                or targets.npc and entity_flags.npc
                or targets.object and entity_flags.object
                or targets.pet and candidate.owner_index == target.me.index then
                    return candidate
                end
            end

            return nil
        end
    end

    local execute_command
    do
        local prefixes = {
            [category_magic] = 'magic',
            [category_job_ability] = 'jobability',
            [category_weapon_skill] = 'weaponskill',
            [category_item] = 'item',
            [category_mount] = 'mount',
        }

        local lookups = {
            [category_magic] = resources.spells,
            [category_job_ability] = resources.job_abilities,
            [category_weapon_skill] = resources.weapon_skills,
            [category_item] = resources.items,
            [category_mount] = resources.mounts,
        }

        execute_command = function(entry, target)
            local category = entry.category
            command.input('/' .. prefixes[category] .. ' "' .. lookups[category][entry.id].name .. '" ' .. tostring(target.id), 'client')
        end
    end

    local get_entry
    do
        local category_action_lookup = {
            [category_magic] = action.spells,
            [category_job_ability] = action.job_abilities,
            [category_weapon_skill] = action.weapon_skills,
            [category_mount] = action.mounts,
        }

        local check_availability = function(category, id)
            if category == category_item then
                return false
            end

            return category_action_lookup[category][id].available
        end

        get_entry = function(entries)
            if entries == nil then
                return nil
            end

            for i = 1, #entries do
                local entry = entries[i]
                if check_availability(entry.category, entry.id) then
                    return entry
                end
            end
        end
    end

    process_command = function(entries, target_string)
        local entry = get_entry(entries)
        if entry == nil then
            return false
        end

        local ok, targets = pcall(parse_targets, entry, target_string)
        if not ok then
            chat.add_text(targets:match(' (.*)'), 167)
            return
        end

        local target_entity = get_target(entry.targets, unpack(targets))
        if target_entity ~= nil then
            execute_command(entry, target_entity)
            return true
        end

        chat.add_text('Cannot cast "' .. category_resources[entry.category][entry.id].name .. '" on "' .. targets[1].name .. '".', 167)
        return true
    end
end

command.core.unknown_command:register(function(_, text, handled)
    if handled.set then
        return
    end

    if process_command(action_map[text:normalize()]) then
        handled.set = true
        return
    end

    local tokens = text:split(' ')
    if #tokens > 1 and process_command(action_map[table.concat(tokens, '', 1, #tokens - 1):normalize()], tokens[#tokens]) then
        handled.set = true
        return
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
