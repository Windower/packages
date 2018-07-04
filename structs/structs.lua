local ffi = require('ffi')
local bit = require('bit')
local string = require('string')
local os = require('os')
local math = require('math')
local table = require('table')
local pack = require('pack')

local structs = {}

local make_cdef = function(arranged, size)
    local cdefs = {}
    local index = 0x00
    local offset = 0
    local bit_type
    local bit_type_size
    local unknown_count = 1
    local cdef_count = 0

    for _, field in ipairs(arranged) do
        -- Can only happen with char*, should only appear at the end
        local type = field.type
        if type.cdef == nil then
            break;
        end

        local is_bit = type.bits ~= nil

        local diff = field.position - index
        if diff > 0 then
            if bit_type then
                cdef_count = cdef_count + 1
                cdefs[cdef_count] = bit_type .. ' __' .. tostring(unknown_count) .. ':' .. tostring(8 * bit_type_size - offset)
                unknown_count = unknown_count + 1

                diff = diff - bit_type_size
                index = index + bit_type_size

                offset = 0
                bit_type = nil
                bit_type_size = nil
            end
            if diff > 0 then
                cdef_count = cdef_count + 1
                cdefs[cdef_count] = 'char __' .. tostring(unknown_count) .. '[' .. tostring(diff) .. ']'
                unknown_count = unknown_count + 1
            end
        end
        index = index + diff

        if is_bit then
            assert(bit_type == nil or type.cdef == bit_type, 'Bit field must have the same base types for every member.')

            local bit_diff = field.offset - offset
            if bit_diff > 0 then
                cdef_count = cdef_count + 1
                cdefs[cdef_count] = (bit_type or type.cdef) .. ' __' .. tostring(unknown_count) .. ':' .. tostring(bit_diff)
                unknown_count = unknown_count + 1
            end
            offset = offset + bit_diff
        end

        cdef_count = cdef_count + 1
        if is_bit then
            cdefs[cdef_count] = type.cdef .. ' ' .. field.cname .. ':' .. tostring(type.bits)
            offset = offset + type.bits
            if offset == 8 * type.size then
                offset = 0
                bit_type = nil
                bit_type_size = nil
            else
                bit_type = type.cdef
                bit_type_size = type.size
            end
        else
            if type.count ~= nil then
                local counts = ''
                local base = type
                while base.count ~= nil do
                    counts = '[' .. tostring(base.count) .. ']' .. counts
                    base = base.base
                end
                cdefs[cdef_count] = type.cdef .. ' ' .. field.cname .. counts
            else
                cdefs[cdef_count] = type.cdef .. ' ' .. field.cname
            end
            index = index + type.size
        end
    end

    if size and index < size then
        cdef_count = cdef_count + 1
        cdefs[cdef_count] = 'char __' .. tostring(unknown_count) .. '[' .. tostring(size - index) .. ']'
    end

    return next(cdefs) and ('struct{' .. table.concat(cdefs, ';') .. ';}') or 'struct{}'
end

local key_map = {
    [1] = 'position',
    [2] = 'type',
}

local type_mt = {
    __index = function(base, count)
        if type(count) ~= 'number' then
            return nil
        end

        return structs.array(base, count)
    end,
}

do
    local cdef_cache = {}

    structs.make_type = function(cdef)
        if cdef_cache[cdef] == nil then
            cdef_cache[cdef] = {
                cdef = cdef,
                ctype = ffi.typeof(cdef),
                size = ffi.sizeof(cdef),
            }
        end

        local info = cdef_cache[cdef]
        return setmetatable({
            cdef = info.cdef,
            ctype = info.ctype,
            size = info.size,
        }, type_mt)
    end
end

structs.copy_type = function(base)
    local new = structs.make_type(base.cdef)

    for key, value in pairs(base) do
        new[key] = value
    end

    return new
end

local keywords = {
    ['auto'] = true,
    ['break'] = true,
    ['case'] = true,
    ['char'] = true,
    ['complex'] = true,
    ['const'] = true,
    ['continue'] = true,
    ['default'] = true,
    ['do'] = true,
    ['double'] = true,
    ['else'] = true,
    ['enum'] = true,
    ['extern'] = true,
    ['float'] = true,
    ['for'] = true,
    ['goto'] = true,
    ['if'] = true,
    ['int'] = true,
    ['long'] = true,
    ['register'] = true,
    ['return'] = true,
    ['short'] = true,
    ['signed'] = true,
    ['sizeof'] = true,
    ['static'] = true,
    ['struct'] = true,
    ['switch'] = true,
    ['typedef'] = true,
    ['union'] = true,
    ['unsigned'] = true,
    ['void'] = true,
    ['volatile'] = true,
    ['while'] = true,
}

do
    local build_type = function(cdef, info)
        local new
        if info ~= nil then
            new = structs.make_type(cdef .. '*')
            new.signature = info[1]
            new.offsets = info.offsets or {}
            new.static_offsets = info.static_offsets or {}
        else
            new = structs.make_type(cdef)
        end

        return new
    end

    structs.array = function(type, count, info)
        local new = build_type(type.cdef, info)

        new.count = count
        new.base = type
        if info == nil then
            new.size = type.size * count
        end

        return new
    end

    structs.struct = function(fields, info, size)
        local arranged = {}
        for label, data in pairs(fields) do
            local full = {
                label = label,
                cname = keywords[label] ~= nil and ('_' .. label) or label,
                offset = 0,
            }

            for key, value in pairs(data) do
                full[key_map[key] or key] = value
            end

            arranged[#arranged + 1] = full
        end

        table.sort(arranged, function(field1, field2)
            return field1.position < field2.position or field1.position == field2.position and field1.offset < field2.offset
        end)

        local new = build_type(make_cdef(arranged), info)

        new.fields = arranged
        if size then
            new.size = size
        end

        return new
    end
end

structs.uint8 = structs.make_type('uint8_t')
structs.uint16 = structs.make_type('uint16_t')
structs.uint32 = structs.make_type('uint32_t')
structs.uint64 = structs.make_type('uint64_t')
structs.int8 = structs.make_type('int8_t')
structs.int16 = structs.make_type('int16_t')
structs.int32 = structs.make_type('int32_t')
structs.int64 = structs.make_type('int64_t')
structs.float = structs.make_type('float')
structs.double = structs.make_type('double')
structs.bool = structs.make_type('bool')

local string_types = {}

structs.string = function(length)
    if not length then
        return {
            tolua = function(raw, field)
                return raw:unpack('z', field.position + 1)
            end,
            toc = function(instance, index, value, field)
                ffi.copy(instance[index], value .. ('\0'):rep(4 - (#value + field.position) % 4))
            end,
        }
    end

    if not string_types[length] then
        local new = structs.make_type('char')[length]

        new.tolua = function(value, field)
            return ffi.string(value)
        end

        new.toc = function(instance, index, value, field)
            ffi.copy(instance[index], #value >= length and value:sub(1, length - 1) .. '\0' or value .. ('\0'):rep(length - #value))
        end

        string_types[length] = new
    end

    return string_types[length]
end

local data_types = {}

structs.data = function(length)
    if not data_types[length] then
        local new = structs.make_type('char')[length]

        new.tolua = function(value, field)
            return ffi.string(value, length)
        end

        new.toc = function(instance, index, value, field)
            ffi.copy(instance[index], #value >= length and value:sub(1, length - 1) .. '\0' or value .. ('\0'):rep(length - #value))
        end

        data_types[length] = new
    end

    return data_types[length]
end

structs.tag = function(base, tag)
    local new = structs.copy_type(base)
    new.tag = tag
    return new
end

structs.time = structs.tag(structs.uint32, 'time')
do
    local now = os.time()
    local off = os.difftime(now, os.time(os.date('!*t', now)))

    structs.time.tolua = function(value, field)
        return value + off
    end

    structs.time.toc = function(instance, index, value, field)
        instance[index] = value - off
    end
end

do
    local band = bit.band
    local bor = bit.bor
    local rshift = bit.rshift
    local lshift = bit.lshift
    local byte = string.byte
    local min = math.min
    local ffi_string = ffi.string

    structs.packed_string = function(size, lookup_string)
        local new = structs.make_type('char')[size]

        local unpacked_size = math.floor(4 * size / 3 + 0.1)
        local type = ffi.typeof('char[' .. unpacked_size .. ']')

        local lua_lookup = {}
        do
            for i = 1, 0x40 do
                local char = lookup_string:sub(i, i)
                lua_lookup[i - 1] = char and char:byte() or 0
            end
        end

        local c_lookup = {}
        for i, v in pairs(lua_lookup) do
            c_lookup[v] = i
        end

        new.tolua = function(value, field)
            local res = type()
            local ptr = res
            for i = 1, size - 2, 3 do
                local v1 = value[0]
                local v2 = value[1]
                local v3 = value[2]
                ptr[0] = lua_lookup[rshift(band(v1, 0xFC), 2)];
                ptr[1] = lua_lookup[bor(lshift(band(v1, 0x03), 4), rshift(band(v2, 0xF0), 4))];
                ptr[2] = lua_lookup[bor(lshift(band(v2, 0x0F), 2), rshift(band(v3, 0xC0), 6))];
                ptr[3] = lua_lookup[band(v3, 0x3F)];
                value = value + 3
                ptr = ptr + 4
            end
            return ffi_string(res)
        end

        new.toc = function(instance, index, value, field)
            for i = 1, min(unpacked_size - 3, #value), 4 do
                local v1, v2, v3, v4 = byte(value, i, i + 3)
                v1 = c_lookup[v1]
                v2 = c_lookup[v2]
                v3 = c_lookup[v3]
                v4 = c_lookup[v4]
                instance[0] = bor(lshift(v1, 2), rshift(v2, 6))
                instance[1] = bor(lshift(v2, 4), rshift(v3, 4))
                instance[2] = bor(lshift(v3, 6), rshift(v4, 2))
                instance = instance + 3
            end
        end

        return new
    end
end

structs.bit = function(base, bits)
    local new = structs.copy_type(base)

    new.bits = bits

    return new
end

structs.boolbit = function(base)
    local new = structs.bit(base, 1)

    new.tolua = function(value, field)
        return value == 1
    end

    new.toc = function(instance, index, value, field)
        instance[index] = value and 1 or 0
    end

    return new
end

structs.ptr = function(base)
    local new = structs.make_type((base and base.cdef or 'void') .. '*')

    new.base = base
    new.ptr = true

    return new
end

return structs

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
