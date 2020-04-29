--[[
Copyright © 2020, JobChange
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of JobChange nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

string = require('string.ext')
table = require('table')
set = require('set')
list = require('list')

packets = require('packets')
client_data = require ('client_data')

entities = require('entities')
player = require('player')
world = require('world')

chat = require('core.chat')
command = require('core.command')settings = require('settings')

local defaults = {
    log_to_chat = false,
}
local options = settings.load(defaults)

local temp_jobs = list(13, 19, 1, 2, 3, 4, 5)
local mog_zones = set('Selbina', 'Mhaura', 'Tavnazian Safehold', 'Nashmau', 'Rabao', 'Kazham', 'Norg')
local moogles = set('Moogle', 'Nomad Moogle', 'Green Thumb Moogle')

local log = function(msg)
    if options.log_to_chat then
        chat.add_text('JobChange: '..msg)
    end
end

local jobchange = function(job_id, is_main)
    local field_name = is_main and 'main_job_id' or 'sub_job_id'
    packets.outgoing[0x100]:inject({
        [field_name] = job_id,
    })
end

local find_job = function(job_name)
    if job_name == nil or job_name == '' then 
        return nil 
    end

    for index, value in pairs(client_data.jobs) do
        local job_level = player.job_levels[index]
        if value.abbreviation:lower() == job_name:lower() and job_level > 0 then 
            return index
        end
    end
end

local find_job_change_npc = function()
    if not (world.mog_house or mog_zones:contains(client_data.zones[world.zone_id].english)) then
        log('Not in a zone with a Change NPC')
        return
    end

    local closest_moogle, closest_distance
    for _, npc in pairs(entities.npcs) do
        if npc ~= nil and not npc.flags.hidden and npc.distance < 36 and moogles:contains(npc.name) then
            if closest_distance == nil or npc.distance < closest_distance then
                closest_moogle = npc
                closest_distance = npc.distance
            end
        end
    end
    return closest_moogle
end

local find_conflict = function(job_id)
    if player.main_job_id == job_id then
        return true
    end
    if player.sub_job_id == job_id then
        return true
    end
end

local find_temp_job = function()
    for _, job_id in pairs(temp_jobs) do -- check temp jobs (nin, dnc, war, mnk, whm, blm, rdm, thf)
        if not find_conflict(job_id) then 
            return job_id
        end
    end
end

local solve_jobchange = function(main_id, sub_id)
    if main_id == nil and sub_id == nil then
        log('No change required.')

        return
    end
    local changes = list()
  
    if main_id ~= nil and main_id == player.sub_job_id then
        if sub_id ~= nil and sub_id == player.main_job_id then
            changes:add({job_id=find_temp_job(), is_conflict=true, is_main=false})
            changes:add({job_id=main_id, is_main=true})
            changes:add({job_id=sub_id, is_main=false})
        else
            if sub_id ~= nil then
                changes:add({job_id=sub_id, is_main=false})
            else
                changes:add({job_id=find_temp_job(), is_conflict=true, is_main=false})
            end
            changes:add({job_id=main_id, is_main=true})
        end
    elseif sub_id ~= nil and sub_id == player.main_job_id then
        if main_id ~= nil then
            changes:add({job_id=main_id, is_main=true})
        else
            changes:add({job_id=find_temp_job(), is_conflict=true, is_main=true})
        end
        changes:add({job_id=sub_id, is_main=false})
    else
        if main_id ~= nil then
            if main_id == player.main_job_id then
                changes:add({job_id=find_temp_job(), is_conflict=true, is_main=true})
            end
            changes:add({job_id=main_id, is_main=true})
        end
        if sub_id ~= nil then
            if sub_id == player.sub_job_id then
                changes:add({job_id=find_temp_job(), is_conflict=true, is_main=false})
            end
            changes:add({job_id=sub_id, is_main=false})
        end
    end
  
    local npc = find_job_change_npc()
    if npc then
        for _, change in ipairs(changes) do
            if change.is_conflict then
                log('Conflict with '..(change.is_main and 'main' or 'sub')..' job. Changing to: '..client_data.jobs[change.job_id].abbreviation)
            else
                log('Changing '..(change.is_main and 'main' or 'sub')..' job to: '..client_data.jobs[change.job_id].abbreviation)
            end
            jobchange(change.job_id, change.is_main)
  
            coroutine.sleep(0.5)
        end
    else
        log('Not close enough to a Moogle!')
    end   
end

local handle_jobchange = function(main_name, sub_name)    
    local main_id = find_job(main_name)
    local sub_id = find_job(sub_name)
  
    if main_name ~= '' and main_id == nil then 
        log('Could not change main job to '..main_name:upper()..' ---Mistype|NotUnlocked')
        return
    end
    local sub_id = find_job(sub_name, p)
    if sub_name ~= '' and sub_id == nil then 
        log('Could not change sub job to '..sub_name:upper()..' ---Mistype|NotUnlocked')
        return
    end

    if main_id == player.main_job_id then 
        main_id = nil 
    end
    if sub_id == player.sub_job_id then 
        sub_id = nil 
    end
  
    coroutine.schedule(solve_jobchange, 0, main_id, sub_id)
end

local handle_reset = function()
    coroutine.schedule(solve_jobchange,0, nil, player.sub_job_id)
end

local handle_command = function(command)
    if command:lower() == 'reset' then
        handle_reset()
    elseif command:contains('/') then
        local main_sub = command:split('/')
        handle_jobchange(table.unpack(main_sub))
    else
        -- assume main job.
        handle_jobchange(command, '')
    end
end

local jc = command.new('jc')
jc:register(handle_command, '<cmd:string()>')