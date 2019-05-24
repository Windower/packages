local bit = require('bit')
local event = require('event')
local shared = require('shared')

local service = shared.get('action_service', 'service')

local get_event = function(name)
    local slim_event = event.slim.new()
    service:read(name):register(function(...)
        slim_event:trigger(...)
    end)
    return slim_event
end

local action = {
    filter_action   = get_event('filter_action'),
    pre_action      = get_event('pre_action'),
    mid_action      = get_event('mid_action'),
    post_action     = get_event('post_action'),
    block           = function()
        service:call(function() block() end)
    end,
}

do
    local band = bit.band
    local rshift = bit.rshift

    local get_flag = function(str,index)
        return band(rshift(str:byte(rshift(index, 3) + 1), band(index, 7)), 1) == 1
    end

    local fn_index = function(t,k)
        return true
        if type(k) == 'number' and k>0 and k<1024 then
            return get_flag(service.spells_known_raw,k)
        else
            return nil
        end
    end

    action.spells_known = setmetatable({},{
        __index = fn_index
    })
end

return action

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
