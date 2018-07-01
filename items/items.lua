local enumerable = require('enumerable')
local res = require('resources')
local shared = require('shared')

local fetch = shared.get('items_service', 'items')

local iterate = function(data, bag, index)
    return next(data.bags[bag], index)
end

local iterate_bag = function(data, bag)
    return next(data.bags, bag)
end

local constructors = setmetatable({}, {
    __index = function(mts, bag)
        local ok = fetch:call(function(data, bag)
            return data.bags[bag] ~= nil
        end, bag)

        assert(ok, 'Unknown bag: ' .. bag)

        local meta = {
            __index = function(_, index)
                if index == 'size' then
                    return fetch:read('sizes', bag)
                end

                return fetch:read('bags', bag, index)
            end,

            __pairs = function(t)
                return function(t, index)
                    return fetch:call(iterate, bag, index)
                end, t, nil
            end,
        }

        local constructor = enumerable.init_type(meta)
        mts[bag] = constructor
        return constructor
    end,
})

return setmetatable({}, {
    __index = function(_, bag)
        if type(bag) == 'string' then
            local lc_bag = bag:lower()
            
            if lc_bag == 'gil' then
                return fetch:read('gil')
            end

            bag = (res.bags:first(function(v, k, t)
                return v.command == lc_bag or v.english:lower() == lc_bag
            end) or {}).id or bag
        end
        return constructors[bag]()
    end,

    __pairs = function(t)
        return function(t, index)
            return fetch:call(iterate_bag, index)
        end, t, nil
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
