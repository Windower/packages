
--[[
Copyright © 2017, Sammeh of Quetzalcoatl
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
DISCLAIMED. IN NO EVENT SHALL Sammeh BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]



string = require('string.ext')
table = require('table')
packets = require('packets')
res = require ('resources')
entities = require('entities')
player = require('player')
set = require('set')
list = require('list')
world = require('world')
chat = require('core.chat')
command = require('core.command')

local temp_jobs = list(13, 19, 1, 2, 3, 4, 5)
local mog_zones = set('Selbina', 'Mhaura', 'Tavnazian Safehold', 'Nashmau', 'Rabao', 'Kazham', 'Norg')
local moogles = set('Moogle', 'Nomad Moogle', 'Green Thumb Moogle')

function log(msg)
    chat.add_text('JobChange: '..msg)
end

event_call = function(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        print('[Error]', err)
    else
        return ok, err
    end
end

function distance_sqd(a, b)
    local dx, dy = b.x-a.x, b.y-a.y
    return dy*dy + dx*dx
end

function jobchange(job, main)
    main = main and "main_job_id" or "sub_job_id"
    packets.outgoing[0x100]:inject({
        [main] = job,
    })
end

function solve_jobchange(mainid, subid)
    if mainid == nil and subid == nil then
        log("No change required.")

        return
    end
    local changes = list()
  
    if mainid ~= nil and mainid == player.sub_job_id then
        if subid ~= nil and subid == player.main_job_id then
            changes:add({job=find_temp_job(),conflict=true,main=false})
            changes:add({job=mainid,main=true})
            changes:add({job=subid,main=false})
        else
            if subid ~= nil then
                changes:add({job=subid,main=false})
            else
                changes:add({job=find_temp_job(),conflict=true,main=false})
            end
            changes:add({job=mainid,main=true})
        end
    elseif subid ~= nil and subid == player.main_job_id then
        if mainid ~= nil then
            changes:add({job=mainid,main=true})
        else
            changes:add({job=find_temp_job(),conflict=true,main=true})
        end
        changes:add({job=subid,main=false})
    else
        if mainid ~= nil then
            if mainid == player.main_job_id then
                changes:add({job=find_temp_job(),conflict=true,main=true})
            end
            changes:add({job=mainid,main=true})
        end
        if subid ~= nil then
            if subid == player.sub_job_id then
                changes:add({job=find_temp_job(),conflict=true,main=false})
            end
            changes:add({job=subid,main=false})
        end
    end
  
    local npc = find_job_change_npc()
    if npc then
        for i, change in ipairs(changes) do
            if change.conflict then
                log("Conflict with "..(change.main and 'main' or 'sub')..' job. Changing to: '..res.jobs[change.job].ens)
            else
                log("Changing "..(change.main and 'main' or 'sub').." job to: "..res.jobs[change.job].ens)
            end
            jobchange(change.job, change.main)
  
            coroutine.sleep(0.5)
        end
    else
        log("Not close enough to a Moogle!")
    end   
end

function handle_jobchange(main, sub)    
    local mainid = find_job(main)
    local subid = find_job(sub)
  
    if main ~= '' and mainid == nil then 
        log("Could not change main job to "..main:upper().." ---Mistype|NotUnlocked")
        return
    end
    local subid = find_job(sub, p)
    if sub ~= '' and subid == nil then 
        log("Could not change sub job to "..sub:upper().." ---Mistype|NotUnlocked")
        return
    end

    print(tostring(player.main_job_id)..'/'..tostring(player.sub_job_id))

    if mainid == player.main_job_id then mainid = nil end
    if subid == player.sub_job_id then subid = nil end
  
    coroutine.schedule(solve_jobchange, 0, mainid, subid)
end

function handle_reset()
    coroutine.schedule(solve_jobchange,0, nil, player.sub_job_id)
end

function handle_command(command)
    if command:lower() == 'reset' then
        handle_reset()
    elseif command:contains('/') then
        mainsub = command:split('/')
        handle_jobchange(table.unpack(mainsub))
    else
        -- assume main job.
        handle_jobchange(command, nil)
    end
end

local jc = command.new('jc')
jc:register(function(cmd) event_call(handle_command, cmd) end, '<cmd:string()>')

function find_conflict(job)
    if player.main_job_id == job then
        return "main"
    end
    if player.sub_job_id == job then
        return "sub"
    end
end

function find_temp_job()
    for _, i in pairs(temp_jobs) do -- check temp jobs (nin, dnc, war, mnk, whm, blm, rdm, thf)
        if not find_conflict(i) then 
            return i
        end
    end
end

function find_job(job)
    if job == nil or job == '' then return nil end
    for index,value in pairs(res.jobs) do
        local jobLevel = player.job_levels[index]
        if value.ens:lower() == job:lower() and jobLevel > 0 then 
            return index
        end
    end
end


function find_job_change_npc()
    if not (world.mog_house or mog_zones:contains(res.zones[world.zone_id].english)) then
        log('Not in a zone with a Change NPC')
        return
    end

    local pos = entities.pcs:by_id(player.id).position
    for i, v in pairs(entities.npcs) do
        if v and distance_sqd(pos, v.position) < 36 and moogles:contains(v.name) then
            return v
        end
    end
end
