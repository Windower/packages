local res = require('resources')
local shared = require('shared')
local entities = require('entities')

local fetch_player = shared.get('player_service', 'player')
local entity_value = {position = true, heading = true, target_index = true}

local indexers = {
    job_levels = function(t, k)
        if type(k) == 'string' then
            local job_id = res.jobs:first(function(v) return (v.english == k or v.english_short == k) end).id
            return rawget(t, job_id) or rawget(t, k)
        end
        return rawget(t, k)
    end,
    nations = function(t, k)
        local nations = {'Bastok','windurst'}
        nations[0] = 'San d\'Oria'
        if k == 'name' then
            return nations[t.id] or ''
        else
            return rawget(t, k)
        end
    end,
    skills = function(t, k)
        if type(k) == 'string' then
            local categories = res.skills:where(function(v) return v.category == k end):totable()
            if #categories ~= 0 then
                return setmetatable({}, {
                        __index = function(_, k2)
                            if type(k2) == 'string' then
                                local skill_id = res.skills:first(function(v) return (v.english == k2 and v.category == k) end).id
                                return rawget(t, skill_id) or rawget(t, k2)
                            end
                            return rawget(t, k2)
                        end,
                        __pairs = function(_)
                            return function(_, k2)
                                local k2, v = next(t, k2)
                                while k2 and res.skills[k2].category ~= k do
                                    k2, v = next(t, k2)
                                end
                                return k2, v
                            end
                        end,
                        __metatable = false,
                    })
            end
            local skill_id = res.skills:first(function(v) return v.english == k end).id
            if rawget(t, skill_id) ~= nil then
                return rawget(t, skill_id)
            end
        end
        return rawget(t, k)
    end,
}

local iterate = function(data, key)
    return next(data, key)
end

local player = setmetatable({}, {
    __index = function(_, k)

        if entity_value[k] then
            return entities[fetch_player:read('index')][k]
        end

        local result = fetch_player:read(k)

        if type(result) ~= 'table' then
            return result
        end

        return setmetatable({}, {
            __index = function(_, l)
                if indexers[k] then
                    return indexers[k](result, l)
                else
                    return result[l]
                end
            end,
            __newindex = function() error('This value is read-only.') end,
            __pairs = function(_) 
                return function(_, k)
                    return next(result, k)
                end
            end,
            __metatable = false,
        })
    end,
    __newindex = function()
        error('This value is read-only.')
    end,
    __pairs = function(t)
        return function(_, k)
            return fetch_player:call(iterate, k)
        end, t, nil
    end,
    __metatable = false,
})

return player

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
