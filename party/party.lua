local memory = require('memory')

local key_fns = {
    alliance = function() return memory.party.members[0].alliance_info end
}

return setmetatable({}, {
    __index = function(_, key)
        if type(key) ~= 'number' then
            local fn = key_fns[key]
            return fn and fn()
        elseif key < 1 or key > 18 then
            return nil
        end

        local member = memory.party.members[key - 1]
        return member.active and member or nil
    end,
    __newindex = function()
        error('Cannot assign to the \'party\' library.')
    end,
    __pairs = function(_)
        return function(t, k)
            if type(k) ~= 'number' then
                local key, fn = next(key_fns, k)
                if key then
                    local res = fn()
                    return key, res ~= nil and res or nil
                end
                k = 0
            end

            k = k + 1
            for i = k, 18 do
                local member = memory.party.members[i - 1]
                if member.active then
                    return i, member
                end
            end

            return nil, nil
        end, key_fns, nil
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
