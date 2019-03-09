local ffi = require('ffi')
local memory = require('memory')
local string = require('string')
local unicode = require('unicode')

local table
local convert
local get
do
    local ffi_string = ffi.string
    local ffi_cast = ffi.cast
    local string_gsub = string.gsub
    local unicode_from_shift_jis = unicode.from_shift_jis

    local int_ptr = ffi.typeof('int*')
    local char_ptr = ffi.typeof('char*')

    table = function(name)
        local raw = ffi_cast(int_ptr, memory.string_tables[name])
        return raw ~= nil and raw + 1 or nil
    end

    convert = function(table, id)
        return string_gsub(unicode_from_shift_jis(ffi_string(ffi_cast(char_ptr, table) + table[id])), '\x07', '\n')
    end

    get = function(name, id)
        local table = table(name)
        if not table then
            return nil
        end

        return convert(table, id)
    end
end

return setmetatable({}, {
    __index = function(_, name)
        return setmetatable({ key = name }, {
            __index = function(t, id)
                return get(t.key, id)
            end,
            __ipairs = pairs,
            __pairs = function(t)
                local table = table(name)
                local size = table ~= nil and table[0] / 4 or 0
                return function(t, k)
                    local key = k + 1
                    if key >= size then
                        return nil, nil
                    end
                    return key, convert(t, key)
                end, table, -1
            end,
            __newindex = error,
            __metatable = false,
        })
    end,
    __newindex = error,
    __metatable = false,
})

--[[
Copyright © 2019, Windower Dev Team
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
