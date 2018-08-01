local ffi = require('ffi')
local bit = require('bit')
local string = require('string')
local os = require('os')
local math = require('math')
local table = require('table')

local structs = {}
local tolua = {}
local toc = {}

local make_cdef
do
    local table_concat = table.concat

    make_cdef = function(arranged, size)
        local cdefs = {}
        local index = 0x00
        local offset = 0
        local bit_type
        local bit_type_size
        local unknown_count = 1
        local cdef_count = 0

        for _, field in ipairs(arranged) do
            -- Can only happen with char*, should only appear at the end
            local ftype = field.type

            local is_bit = ftype.bits ~= nil

            if field.position then
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
            end

            if is_bit then
                assert(bit_type == nil or ftype.cdef == bit_type, 'Bit field must have the same base types for every member.')

                local bit_diff = field.offset - offset
                if bit_diff > 0 then
                    cdef_count = cdef_count + 1
                    cdefs[cdef_count] = (bit_type or ftype.cdef) .. ' __' .. tostring(unknown_count) .. ':' .. tostring(bit_diff)
                    unknown_count = unknown_count + 1
                end
                offset = offset + bit_diff
            end

            cdef_count = cdef_count + 1
            if is_bit then
                cdefs[cdef_count] = ftype.cdef .. ' ' .. field.cname .. ':' .. tostring(ftype.bits)
                offset = offset + ftype.bits
                if offset == 8 * ftype.size then
                    offset = 0
                    bit_type = nil
                    bit_type_size = nil
                    index = index + ftype.size
                else
                    bit_type = ftype.cdef
                    bit_type_size = ftype.size
                end
            else
                local suffix = ''
                local cdef = ftype.name or ftype.cdef
                if ftype.count ~= nil then
                    local counts = ''
                    local base = ftype
                    while base.count ~= nil do
                        counts =  counts .. '[' .. (base.count == '*' and '?' or tostring(base.count)) .. ']'
                        base = base.base
                    end
                    suffix = counts
                    cdef = base.name or base.cdef
                end

                cdefs[cdef_count] = cdef .. ' ' .. field.cname .. suffix

                if ftype.size ~= '*' then
                    index = index + ftype.size
                end
            end
        end

        if size and index < size then
            cdef_count = cdef_count + 1
            cdefs[cdef_count] = 'char __' .. tostring(unknown_count) .. '[' .. tostring(size - index) .. ']'
        end

        return cdef_count > 0 and ('struct{' .. table_concat(cdefs, ';') .. ';}') or 'struct{}', size or index
    end
end

do
    local ffi_sizeof = ffi.sizeof

    local type_mt = {
        __index = function(base, count)
            if type(count) ~= 'number' and count ~= '*' then
                return nil
            end

            local ftype = structs.make_type(base.cdef)

            ftype.base = base
            ftype.count = count
            ftype.size = count == '*' and '*' or base.size * count

            return ftype
        end,
    }

    structs.make_type = function(cdef, info)
        return setmetatable({
            cdef = cdef,
            size = info and info.size or ffi_sizeof(cdef),
        }, type_mt)
    end
end

structs.copy_type = function(base)
    local ftype = structs.make_type(base.cdef)

    for key, value in pairs(base) do
        ftype[key] = value
    end

    return ftype
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
    local string_gsub = string.gsub
    local ffi_metatype = ffi.metatype
    local ffi_sizeof = ffi.sizeof

    local build_type = function(cdef, info)
        local ftype = structs.make_type(cdef, info)
        if info.signature then
            ftype.signature = info.signature
            ftype.offsets = info.offsets or {}
            ftype.static_offsets = info.static_offsets or {}
        end

        if info.size then
            ftype.size = info.size
        end

        if not info.name then
            info.name = '_' .. string_gsub(tostring(ftype), '%W', '')
        end

        structs.name(ftype, info.name)

        return ftype
    end

    structs.array = function(base, count, info)
        info = info or {}

        local ftype = build_type(base.cdef, info)

        ftype.base = base
        ftype.count = count
        ftype.size = count == '*' and '*' or base.size * count

        return ftype
    end

    local ffi_sizeof = ffi.sizeof
    local table_sort = table.sort

    structs.struct = function(fields, info)
        fields, info = info or fields, info and fields or {}

        local arranged = {}
        local arranged_index = 0
        for label, field in pairs(fields) do
            field.label = label
            field.type = field[2] or field[1]
            field.position = field[2] and field[1]
            field.cname = (field.type.converter or keywords[label]) and ('_' .. label) or label
            field.offset = 0

            arranged_index = arranged_index + 1
            arranged[arranged_index] = field
        end

        local first = arranged[1]
        if first and first.position then
            table_sort(arranged, function(field1, field2)
                return field1.position < field2.position or field1.position == field2.position and field1.offset < field2.offset
            end)
        end

        local cdef, size = make_cdef(arranged, info.size)
        info.size = size
        local ftype = build_type(cdef, info)

        local last = arranged[arranged_index]
        local last_ftype = last and last.type
        if last_ftype and last_ftype.size == '*' then
            ftype.var_size = ffi_sizeof(last_ftype.cdef)
        end

        ftype.info = info
        ftype.fields = fields
        ftype.arranged = arranged

        ffi_metatype(ftype.name, {
            __index = function(cdata, key)
                local field = fields[key]
                if not field then
                    return nil
                end

                local cname = field.cname

                local converter = field.type.converter
                if not converter then
                    return cdata[cname]
                end

                return tolua[converter](cdata[cname], field)
            end,
            __newindex = function(cdata, key, value)
                local field = fields[key]
                if not field then
                    error('Cannot set value ' .. key .. '.')
                end

                local cname = field.cname

                local converter = field.type.converter
                if not converter then
                    cdata[cname] = value
                    return
                end

                toc[converter](cdata, cname, value, field)
            end,
            __pairs = function(cdata)
                return function(t, k)
                    local label, field = next(t, k)
                    return label, label and cdata[field.label]
                end, fields, nil
            end,
        })

        return ftype
    end
end

do
    local ffi_cdef = ffi.cdef
    local string_sub = string.sub

    local declared_cache = {}

    structs.name = function(ftype, name)
        ftype.name = name

        local declared = declared_cache[name]
        if declared then
            ffi_cdef('typedef struct ' .. declared.tag .. ' ' .. name .. ';')
            ffi_cdef('struct ' .. declared.tag .. ' ' .. string_sub(ftype.cdef, 7) .. ';')

            for i = 1, #declared.ptrs do
                declared.ptrs[i].base = ftype
            end

            declared_cache[name] = nil
        else
            ffi_cdef('typedef ' .. ftype.cdef .. ' ' .. name .. ';')
        end
    end

    structs.declare = function(name)
        local tag = name .. '_tag'
        ffi_cdef('struct ' .. tag .. ';')
        ffi_cdef('typedef struct ' .. tag .. ' ' .. name .. ';')

        declared_cache[name] = {
            tag = tag,
            ptrs = {},
        }
    end

    structs.ptr = function(base)
        local is_tag = type(base) == 'string'

        local base_def = not base and 'void' or is_tag and base or base.name or base.cdef
        local ftype = structs.make_type(base_def .. '*')

        ftype.ptr = true

        if is_tag then
            local ptrs = declared_cache[base].ptrs
            ptrs[#ptrs + 1] = ftype
        else
            ftype.base = base
        end

        return ftype
    end
end

structs.tag = function(base, tag)
    local ftype = structs.copy_type(base)
    ftype.tag = tag
    return ftype
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

do
    local ffi_string = ffi.string
    local ffi_copy = ffi.copy

    structs.string = function(size)
        local ftype = structs.make_type('char')[size or '*']
        ftype.converter = 'string'

        return ftype
    end

    tolua.string = function(value, field)
        return ffi_string(value)
    end

    toc.string = function(instance, index, value, field)
        ffi_copy(instance[index], value)
    end

    structs.data = function(size)
        local ftype = structs.make_type('char')[size or '*']
        ftype.converter = 'data'

        return ftype
    end

    tolua.data = function(value, field)
        return ffi_string(value, field.type.size)
    end

    toc.data = function(instance, index, value, field)
        ffi_copy(instance[index], value, field.type.size)
    end
end

structs.time = structs.tag(structs.uint32, 'time')
structs.time.converter = 'time'
do
    local now = os.time()
    local off = os.difftime(now, os.time(os.date('!*t', now)))

    tolua.time = function(value, field)
        return value + off
    end

    toc.time = function(instance, index, value, field)
        instance[index] = value - off
    end
end

do
    local band = bit.band
    local bor = bit.bor
    local rshift = bit.rshift
    local lshift = bit.lshift
    local math_min = math.min
    local math_floor = math.floor
    local ffi_string = ffi.string
    local ffi_typeof = ffi.typeof
    local string_sub = string.sub
    local string_byte = string.byte

    structs.packed_string = function(size, lookup_string)
        local ftype = structs.make_type('char')[size]
        ftype.converter = 'packed_string'

        local unpacked_size = math_floor(4 * size / 3 + 0.1)
        ftype.ctype = ffi_typeof('char[' .. unpacked_size .. ']')
        ftype.unpacked_size = unpacked_size

        local lua_lookup = {}
        do
            for i = 1, 0x40 do
                local char = string_sub(lookup_string, i, i)
                lua_lookup[i - 1] = char and string_byte(char) or 0
            end
        end

        local c_lookup = {}
        for i, v in pairs(lua_lookup) do
            c_lookup[v] = i
        end

        ftype.lua_lookup = lua_lookup
        ftype.c_lookup = c_lookup

        return ftype
    end

    tolua.packed_string = function(value, field)
        local ftype = field.type
        local lua_lookup = ftype.lua_lookup
        local res = ftype.ctype()
        local ptr = res
        for i = 1, ftype.size - 2, 3 do
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

    toc.packed_string = function(instance, index, value, field)
        local ftype = field.type
        local c_lookup = ftype.c_lookup
        for i = 1, math_min(ftype.unpacked_size - 3, #value), 4 do
            local v1, v2, v3, v4 = string_byte(value, i, i + 3)
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
end

structs.bit = function(base, bits)
    local ftype = structs.copy_type(base)

    ftype.bits = bits

    return ftype
end

structs.boolbit = function(base)
    local ftype = structs.bit(base, 1)

    ftype.converter = 'boolbit'

    return ftype
end

tolua.boolbit = function(value, field)
    return value == 1
end

toc.boolbit = function(instance, index, value, field)
    instance[index] = value and 1 or 0
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
