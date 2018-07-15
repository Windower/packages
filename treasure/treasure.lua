local packets = require("packets")

local treasure = {}

packets.incoming[0x0D2]:register(function(p)
    if p.item_id ~= 0 then
        treasure[p.pool_location] = {
            dropper_id      = p.dropper_id,
            count           = p.count,
            item_id         = p.item_id,
            dropper_index   = p.dropper_index,
            pool_location   = p.pool_location,
            is_old          = p.is_old,
            timestamp       = p.timestamp,
        }
    end

    if p.dropper_id == 0 then
        treasure[p.pool_location] = nil
    end
end)

packets.incoming[0x0D3]:register(function(p)
    if p.drop ~= 0 then
        treasure[p.pool_location] = nil
    end
end)

return setmetatable({}, {
    __index = function(_, k)
        return treasure[k]
    end,

    __newindex = function()
        return error('This value is read-only.')
    end,

    __pairs = function(_)
        return function(_, k)
            return next(treasure, k)
        end
    end,

    __len = function()
        local count = 0
        for _ in pairs(treasure) do
            count = count + 1
        end
        return count
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
