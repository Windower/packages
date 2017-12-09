local shared = require('shared')
local enumerable = require('enumerable')

local fetch = shared.get('resources_service', 'resources')

local indexer = function(data, resource_name, index)
    return data[resource_name][index]
end

local iterator = function(data, resource_name, index)
    return {next(data[resource_name], index)}
end

local constructors = setmetatable({}, {
    __index = function(mts, resource_name)
        local success, data = fetch(function(data, resource_name)
            return data[resource_name] ~= nil
        end, resource_name)

        if not success then
            error(data)
        end

        if not data then
            error('Resource "' .. resource_name .. '" not found.')
        end

        local meta = {}

        meta.__index = function(t, index)
            local success, data = fetch(indexer, resource_name, index)

            if not success then
                error(data)
            end

            return data
        end

        meta.__pairs = function(t)
            return function(t, index)
                local success, data = fetch(iterator, resource_name, index)

                if not success then
                    error(data)
                end

                return unpack(data)
            end, t, nil
        end

        meta.__add_element = function(t, el)
            print('Adding...', t, el.english)
            rawset(t, el.id, el)
        end

        local constructor = enumerable.init_type(meta)
        mts[resource_name] = constructor
        return constructor
    end,
})

return setmetatable({}, {
    __index = function(_, resource_name)
        return constructors[resource_name]()
    end
})

--[[
Copyright © 2017, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
