local enumerable = require('enumerable')
local res = require('resources')
local shared = require('shared')

local fetch = shared.get('items_service', 'equipment')

local iterate = function(data, index)
    return next(data, index)
end

local equip_meta = {
    __index = function(t, index)
        if type(index) == 'string' then
            local lc_slot = index:lower()
            index = (res.slots:first(function(v, k, t)
                return v.english:lower() == lc_slot
            end) or {}).id or index
        end
        
        return fetch:read(index)
    end,

    __newindex = function()
        error('The equipment structure is read-only.')
    end,

    __pairs = function(t)
        return function(t, index)
            return fetch:call(iterate, index)
        end, t, nil
    end,
}

return enumerable.init_type(equip_meta)()

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
