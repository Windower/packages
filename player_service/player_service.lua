local bit = require('bit')
local pack = require('pack')
local packet = require('packet')
local packets = require('packets')
local res = require('resources')
local shared = require('shared')

player = shared.new('player')

player.env = {
    next = next,
}
  
player.data = {
    linkshell1 = { message = {}, },
    linkshell2 = { message = {}, },
    skills = { combat = {}, crafting = {} },
    model = {},
    job_levels = {},
    position = {},
}

do
    local skills = player.data.skills.combat
    for i = 0x00, 0x2F do
        skills[i] = {}
    end
end
do
    local skills = player.data.skills.crafting
    for i = 0x00, 0x09 do
        skills[i] = {}
    end
end
    

packets.incoming[0x00D]:register(function(p)
    local data = player.data
    if p.player_id ~= data.id then
        return
    end

    if p.update_position then
        local pos = data.position
        pos.heading = p.heading
        pos.x = p.x
        pos.y = p.y
        pos.z = p.z

        data.target_index = p.target_index
        data.movement_speed = p.movement_speed / 8
        data.animation_speed = p.animation_speed / 8
    end

    if p.update_vitals then
        data.hp_percent = p.hp_percent
        data.state = p.state
        data.linkshell1.red = p.linkshell_red
        data.linkshell1.green = p.linkshell_green
        data.linkshell1.blue = p.linkshell_blue
    end

    if p.update_name then
        data.name = p.name
    end

    if p.update_model then
        local model = data.model
        local m = p.model
        model.face = m.face
        model.race = m.race
        model.head = m.head
        model.body = m.body
        model.hands = m.hands
        model.legs = m.legs
        model.feet = m.feet
        model.main = m.main
        model.sub = m.sub
        model.range = m.range
    end
end)

packets.incoming[0x00A]:register(function(p)
    local data = player.data
    data.id = p.player_id
    data.index = p.player_index
    data.name = p.player_name
    data.main_job_id = p.main_job_id
    data.sub_job_id = p.sub_job_id
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
    data.hp_percent = p.hp_percent
end)

packets.incoming[0x01B]:register(function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
    for i = 0, 0x17 do
        data.job_levels[i] = p.job_levels[i]
    end
end)

packets.incoming[0x037]:register(function(p)
    local data = player.data
    data.id = p.player_id
    data.hp_percent = p.hp_percent
    data.state = p.state
    data.linkshell1.red = p.linkshell1_red
    data.linkshell1.green = p.linkshell1_green
    data.linkshell1.blue = p.linkshell1_blue
    data.pet_index = p.pet_index
end)

packets.incoming[0x061]:register(function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
    data.title_id = p.title_id
    data.nation_rank = p.nation_rank
    data.nation_rank_points = p.nation_rank_points
    data.home_point_zone_id = p.home_point_zone_id
    data.nation_id = p.nation_id
    data.superior_level = p.superior_level
    data.item_level = p.item_level_over_99 + p.main_job_level
    data.exp = p.exp
    data.exp_required = p.exp_required
end)

--[[ #BYRTH# I am not sure what this was meant to be
packets.incoming[0x062]:register(function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
end)]]

packets.incoming[0x062]:register(function(p)
    local data = player.data.skills
    local combat = data.combat
    local crafting = data.crafting
    for i = 0x00, 0x2F do
        local skill = combat[i]
        local packet = p.combat_skills[i]
        skill.level = packet.level
        skill.capped = packet.capped
    end
    for i = 0x00, 0x09 do
        local skill = crafting[i]
        local packet = p.crafting_skills[i]
        skill.level = packet.level
        skill.rank_id = packet.rank_id
        skill.capped = packet.capped
    end
end)

packets.incoming[0x0CC]:register(function(p)
    local ls_number = bit.band(p.flags, 0x40) == 0x40 and 2 or 1
    local data = player.data['linkshell' .. ls_number]
    data.name = p.linkshell_name
    data.message.text = p.message
    data.message.player_name = p.player_name
    data.message.timestamp = p.timestamp
    data.message.permissions = p.permissions
end)

packets.incoming[0x0DF]:register(function(p)
    local data = player.data
    if data.id ~= p.id then
        return
    end

    data.id = p.id
    data.index = p.index
    data.hp = p.hp
    data.mp = p.mp
    data.tp = p.tp
    data.hp_percent = p.hp_percent
    data.mp_percent = p.mp_percent
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job
    data.sub_job_level = p.sub_job_level
end)

packets.incoming[0x0E2]:register(function(p)
    local data = player.data
    if data.id ~= p.id then
        return
    end

    data.id = p.id
    data.index = p.index
    data.hp = p.hp
    data.mp = p.mp
    data.tp = p.tp
    data.hp_percent = p.hp_percent
    data.mp_percent = p.mp_percent
end)

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
