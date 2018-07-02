local shared = require('shared')

local fetch_data = shared.get('linkshell_service', 'linkshell')

local iterate = function(data, key)
    return next(data, key)
end

local linkshell = setmetatable({}, {
    __index = function(_, k)
        local result = fetch_data:read(k)

        if type(result) ~= 'table' then
            return result
        end

        return setmetatable({}, {
            __index = function(_, l)
                __index = function(_, l)
                    return result[l]
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
            return fetch_data:call(iterate, k)
        end, t, nil
    end,
    __metatable = false,
})

return linkshell

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
