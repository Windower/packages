local account = require('account')
local event = require('core.event')
local os = require('os')
local packet = require('packet')
local player = require('player')
local resources = require('resources')
local server = require('shared.server')
local struct = require('struct')
local table = require('table')
local world = require('world')

local os_clock = os.clock

local spell_ftype = struct.struct({
    _recast_end         = {struct.double},
    learned             = {struct.bool},
    _level_requirements = {struct.bool},
})

local job_ability_ftype = struct.struct({
    _recast_id          = {struct.int32},
    available           = {struct.bool},
})

local job_ability_recast_ftype = struct.struct({
    recast_end         = {struct.double},
})

local weapon_skill_ftype = struct.struct({
    available           = {struct.bool},
})

local mount_ftype = struct.struct({
    available           = {struct.bool},
})

local spells_count = packet.incoming[0x0AA].type.fields.spells.type.count
local job_abilities_count = packet.incoming[0x0AC].type.fields.job_abilities.type.count
local weapon_skills_count = packet.incoming[0x0AC].type.fields.weapon_skills.type.count
local mounts_count = packet.incoming[0x0AE].type.fields.mounts.type.count

local data, data_ftype = server.new(struct.struct({
    action              = {struct.struct({
        category            = {struct.int32},
        id                  = {struct.int32},
        target_ids          = {struct.int32[15]},
        blocked             = {struct.bool},
    })},
    filter_action       = {data = event.new()},
    pre_action          = {data = event.new()},
    mid_action          = {data = event.new()},
    post_action         = {data = event.new()},
    category            = {struct.struct({
        magic               = {struct.int32, static = 0},
        job_ability         = {struct.int32, static = 1},
        weapon_skill        = {struct.int32, static = 2},
        ranged_attack       = {struct.int32, static = 3},
        item                = {struct.int32, static = 4},
        pet_ability         = {struct.int32, static = 5},
        mount               = {struct.int32, static = 6},
    })},
    spells              = {spell_ftype[spells_count]},
    job_ability_recasts = {job_ability_recast_ftype[0x100]},
    job_abilities       = {job_ability_ftype[job_abilities_count]},
    weapon_skills       = {weapon_skill_ftype[weapon_skills_count]},
    mounts              = {mount_ftype[mounts_count]},
}))

local filter_action_event = data.filter_action
local pre_action_event = data.pre_action
local mid_action_event = data.mid_action
local post_action_event = data.post_action

local action = data.action
local target_ids = action.target_ids
local target_ids_length = #target_ids
local category = data.category

local data_spells = data.spells
local data_job_ability_recasts = data.job_ability_recasts
local data_job_abilities = data.job_abilities
local data_weapon_skills = data.weapon_skills
local data_mounts = data.mounts

do
    local resources_job_abilities = resources.job_abilities
    for id = 0, job_abilities_count - 1 do
        local job_ability = data_job_abilities[id]
        local resource = resources_job_abilities[id]
        if resource ~= nil then
            job_ability._recast_id = resource.recast_id
        end
    end
end

struct.reset_on(account.logout, data, data_ftype)
struct.reset_on(world.zone_change, data_spells, data_ftype.fields.spells.type)

local outgoing_categories = {
    [3] = category.magic,
    [7] = category.weapon_skill,
    [9] = category.job_ability,
    [16] = category.ranged_attack,
}

local incoming_categories = {
    [2] = category.ranged_attack,
    [3] = category.weapon_skill,
    [4] = category.magic,
    [5] = category.item,
    [6] = category.job_ability,
    [13] = category.pet_ability,
    [14] = category.job_ability,
    [15] = category.job_ability,
}

local action_tag = 0xACCE
local tag_field = '_known1'

local backups = {}

local handle_outgoing_action
do
    local table_remove = table.remove

    handle_outgoing_action = function(p, info)
        local action_category = outgoing_categories[p.action_category]
        if info.blocked or action_category == nil then
            return
        end

        if info.injected and p[tag_field] == action_tag then
            p[tag_field] = backups[1]
            table_remove(backups, 1)
            return
        end

        target_ids[0] = p.target_id
        for i = 1, target_ids_length - 1 do
            target_ids[i] = 0
        end

        action.category = action_category
        action.id = p.param

        filter_action_event:trigger()
        info.blocked = true

        if action.blocked then
            action.blocked = false
            return
        end

        pre_action_event:trigger()

        backups[#backups + 1] = p[tag_field]
        packet.outgoing[0x01A]:inject({
            target_id = p.target_id,
            target_index = p.target_index,
            action_category = p.action_category,
            param = p.param,
            [tag_field] = action_tag,
            x_offset = p.x_offset,
            y_offset = p.y_offset,
            z_offset = p.z_offset,
        })

        if action_category == category.magic or action_category == category.job_ability or action_category == category.weapon_skill then
            mid_action_event:trigger()
        end
    end
end

local handle_incoming_action = function(p)
    local action_category = incoming_categories[p.category]
    if not action_category or p.actor ~= player.id then
        return
    end

    local target_count = p.target_count
    for i = 0, target_ids_length - 1 do
        target_ids[i] = i < target_count and p.targets[i + 1].id or 0
    end

    action.category = action_category
    local id = p.param
    action.id = id

    if action_category == category.magic then
        data_spells[id]._recast_end = os_clock() + p.recast
    end

    post_action_event:trigger()
end

packet.outgoing[0x01A]:register(handle_outgoing_action)
packet.incoming[0x028]:register(handle_incoming_action)

do
    local spell_levels = struct.new(struct.uint32[0x18][spells_count])

    for id, spell in pairs(resources.spells) do
        local spell_level_source = spell.levels
        local spell_level_target = spell_levels[id]
        for job_id = 0, 0x18 - 1 do
            spell_level_target[job_id] = spell_level_source[job_id] or 0xFFFFFFFF
        end
    end

    local adjust_spell_requirements = function()
        local main_job_id = player.main_job_id
        local main_job_level = player.main_job_level
        local sub_job_id = player.sub_job_id
        local sub_job_level = player.sub_job_level

        for id, spell in pairs(data_spells) do
            local levels = spell_levels[id]
            spell._level_requirements = main_job_level >= levels[main_job_id] or sub_job_level >= levels[sub_job_id]
        end
    end

    player.job_change:register(adjust_spell_requirements)
end

packet.incoming:register_init({
    [{0x0AA}] = function(p)
        local spells = p.spells
        for id = 0, spells_count - 1 do
            data_spells[id].learned = spells[id]
        end
    end,

    [{0x0AC}] = function(p)
        local job_abilities = p.job_abilities
        for id = 0, job_abilities_count - 1 do
            data_job_abilities[id].available = job_abilities[id]
        end

        local weapon_skills = p.weapon_skills
        for id = 0, weapon_skills_count - 1 do
            data_weapon_skills[id].available = weapon_skills[id]
        end
    end,

    [{0x0AE}] = function(p)
        local mounts = p.mounts
        for id = 0, mounts_count - 1 do
            data_mounts[id].available = mounts[id]
        end
    end,

    [{0x119}] = function(p)
        local now = os_clock()

        for slot, recast in pairs(p.recasts) do
            local recast_id = recast.recast_id
            if slot > 0 and recast_id == 0 then
                break
            end

            data_job_ability_recasts[recast_id].recast_end = now + recast.duration
        end
    end,
})

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
