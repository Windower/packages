local event = require('core.event')
local packet = require('packet')
local player = require('player')
local server = require('shared.server')
local struct = require('struct')

local data = server.new(struct.struct({
    action              = {struct.struct({
        category        = {struct.int32},
        id              = {struct.int32},
        target_ids      = {struct.int32[15]},
        blocked         = {struct.bool},
    })},
    filter_action       = {data = event.new()},
    pre_action          = {data = event.new()},
    mid_action          = {data = event.new()},
    post_action         = {data = event.new()},
    category            = {struct.struct({
        magic           = {struct.int32, static = 0},
        job_ability     = {struct.int32, static = 1},
        weapon_skill    = {struct.int32, static = 2},
        ranged_attack   = {struct.int32, static = 3},
        item            = {struct.int32, static = 4},
        pet_ability     = {struct.int32, static = 5},
    })},
}))

local filter_action_event = data.filter_action
local pre_action_event = data.pre_action
local mid_action_event = data.mid_action
local post_action_event = data.post_action

local action = data.action
local target_ids = action.target_ids
local target_ids_length = #target_ids
local category = data.category

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

local handle_outgoing_action = function(p, info)
    local action_category = outgoing_categories[p.action_category]
    if info.injected or info.blocked or not action_category then
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

    packet.outgoing[0x01A]:inject({
        target_id = p.target_id,
        target_index = p.target_index,
        action_category = p.action_category,
        param = p.param,
        x_offset = p.x_offset,
        y_offset = p.y_offset,
        z_offset = p.z_offset,
    })

    if action_category == category.magic or action_category == category.ranged_attack then
        mid_action_event:trigger()
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
    action.id = p.param

    post_action_event:trigger()
end

packet.outgoing[0x01A]:register(handle_outgoing_action)
packet.incoming[0x028]:register(handle_incoming_action)

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
