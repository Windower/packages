local shared = require('shared')
local packets = require('packets')

player = shared.new('player')

player.env = {
    next = next,
}

player.data = {
    skills = {},
    model = {},
    job_levels = {},
}

do
    local skills = player.data.skills
    for i = 0x00, 0x38 do
        skills[i] = {}
    end
end

packets.incoming:register_init({
    [{0x00D}] = function(p)
        local data = player.data
        if p.player_id ~= data.id then
            return
        end

        if p.update_position then
            data.movement_speed = p.movement_speed / 8
            data.animation_speed = p.animation_speed / 8
        end

        if p.update_vitals then
            data.hp_percent = p.hp_percent
            data.state = p.state
        end

        if p.update_name then
            data.name = p.name
        end

        if p.update_model then
            local model = data.model
            local m = p.model
            data.race_id = m.race_id
            model.face_id = m.face_model_id
            model.head_id = m.head_model_id
            model.body_id = m.body_model_id
            model.hands_id = m.hands_model_id
            model.legs_id = m.legs_model_id
            model.feet_id = m.feet_model_id
            model.main_id = m.main_model_id
            model.sub_id = m.sub_model_id
            model.range_id = m.range_model_id
        end
    end,

    [{0x00A}] = function(p)
        local data = player.data
        data.id = p.player_id
        data.index = p.player_index
        data.name = p.player_name
        data.main_job_id = p.main_job_id
        data.sub_job_id = p.sub_job_id
        data.hp_max = p.hp_max
        data.mp_max = p.mp_max
        data.hp_percent = p.hp_percent
    end,

    [{0x01B}] = function(p)
        local data = player.data
        data.race_id = p.race_id
        data.main_job_id = p.main_job_id
        data.sub_job_id = p.sub_job_id
        data.hp_max = p.hp_max
        data.mp_max = p.mp_max
        for i = 0, 0x17 do
            data.job_levels[i] = p.job_levels[i]
        end
    end,

    [{0x037}] = function(p)
        local data = player.data
        data.id = p.player_id
        data.hp_percent = p.hp_percent
        data.state = p.state
        data.pet_index = p.pet_index
    end,

    [{0x061}] = function(p)
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
    end,

    [{0x062}] = function(p)
        local skills = player.data.skills
        for i = 0x00, 0x2F do
            local skill = skills[i]
            local packet = p.combat_skills[i]
            skill.level = packet.level
            skill.capped = packet.capped
        end
        for i = 0x00, 0x09 do
            local skill = skills[i + 0x2F]
            local packet = p.crafting_skills[i]
            skill.level = packet.level
            skill.rank_id = packet.rank_id
            skill.capped = packet.capped
        end
    end,

    [{0x0DF}] = function(p)
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
    end,

    [{0x0E2}] = function(p)
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
    end,
})

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
