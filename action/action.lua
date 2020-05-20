local client = require('shared.client')
local entities = require('entities')
local event = require('core.event')

local data, ftype = client.new('action_service')

ftype.fields.action.type.fields.targets = {
    get = function(data)
        local target_ids = data.target_ids
        local target_ids_length = #target_ids
        return setmetatable({}, {
            __len = function(_)
                for i = 0, target_ids_length - 1 do
                    if target_ids[i] == 0 then
                        return i
                    end
                end
                return target_ids_length
            end,
            __index = function(_, k)
                return entities:by_id(target_ids[k])
            end,
            __pairs = function(t)
                return function(t, k)
                    k = k + 1
                    if k == target_ids_length then
                        return nil, nil
                    end

                    return k, t[k]
                end, t, -1
            end,
            __ipairs = pairs,
            __newindex = error,
            __metatable = false,
        })
    end,
}

local get_event = function(service_event)
    local ev = event.new()
    service_event:register(function()
        ev:trigger(data.action)
    end)
    return ev
end

return {
    filter_action = get_event(data.filter_action),
    pre_action = get_event(data.pre_action),
    mid_action = get_event(data.mid_action),
    post_action = get_event(data.post_action),
}

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
