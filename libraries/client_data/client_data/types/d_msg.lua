local ffi = require('ffi')
local struct = require('struct')
local unicode = require('core.unicode')

local ffi_cast = ffi.cast
local ffi_string = ffi.string
local unicode_from_shift_jis = unicode.from_shift_jis

local byte_ptr = ffi.typeof('uint8_t*')
local int_ptr = ffi.typeof('uint32_t*')

local header_type = struct.struct({
    format          = {0x00, struct.string(0x08)},
    type            = {0x08, struct.uint16},
    encrypted       = {0x0A, struct.bool},
    version1        = {0x0C, struct.uint32},
    version2        = {0x10, struct.uint32},
    file_size       = {0x14, struct.uint32},
    header_size     = {0x18, struct.uint32},
    table_size      = {0x1C, struct.uint32},
    entry_size      = {0x20, struct.uint32}, -- Maybe not set in memory? Is zero, at least for weather strings
    data_size       = {0x24, struct.uint32},
    count           = {0x28, struct.uint32},
})

local offset_from_table = function(id, table, entry_size)
    return table[2 * id]
end

local offset_from_entry_size = function(id, table, entry_size)
    return id * entry_size
end

local build_index = function(ptr, header, lookup)
    local table = ffi_cast(int_ptr, ptr + header.header_size)
    local data = ptr + header.header_size + header.table_size

    if header.type == 0x10 then
        return function(_, id)
            return (unicode_from_shift_jis(ffi_string(data + table[2 * id])))
        end
    end

    local entry_size = header.entry_size
    local get_offset = entry_size ~= 0 and offset_from_entry_size or offset_from_table

    return function(_, id)
        local entry = data + get_offset(id, table, entry_size)
        local entry_table = ffi_cast(int_ptr, entry + 4)

        local res = {}
        for index = 0, ffi_cast(int_ptr, entry)[0] - 1 do
            local type = entry_table[2 * index + 1]
            local item_ptr = entry + entry_table[2 * index]
            if type == 0 then
                res[index + 1] = (unicode_from_shift_jis(ffi_string(item_ptr + 0x1C)))
            elseif type == 1 then
                res[index + 1] = ffi_cast(int_ptr, item_ptr)[0]
            end
        end

        for name, index in pairs(lookup) do
            res[name] = res[index + 1]
        end

        return res
    end
end

return {
    new = function(ptr, lookup)
        ptr = ffi_cast(byte_ptr, ptr)
        lookup = lookup or {}

        local header = struct.from_ptr(header_type, ptr)
        local size = header.count

        return setmetatable({}, {
            __index = build_index(ptr, header, lookup),
            __pairs = function(t)
                return function(t, k)
                    k = k + 1
                    if k >= size then
                        return nil, nil
                    end

                    return k, t[k]
                end, t, -1
            end,
            __ipairs = pairs,
            __len = function(_)
                return size
            end,
            __newindex = error,
            __metatable = false,
        })
    end,
}

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
