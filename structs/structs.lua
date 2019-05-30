local ffi = require('ffi')
local bit = require('bit')
local string = require('string')
local os = require('os')
local math = require('math')
local table = require('table')
local windower = require('windower')

local assert = assert
local error = error
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local type = type

local structs = {}
local tolua = {}
local toc = {}

local make_struct_cdef
do
    local table_concat = table.concat

    make_struct_cdef = function(arranged, size)
        local cdefs = {}
        local index = 0x00
        local offset = 0
        local bit_type
        local bit_type_size
        local unknown_count = 0
        local cdef_count = 0

        for i = 1, #arranged do
            local field = arranged[i]
            local ftype = field.type

            local is_bit = ftype.bits ~= nil

            if field.position then
                local diff = field.position - index
                if diff > 0 then
                    if bit_type then
                        cdef_count = cdef_count + 1
                        unknown_count = unknown_count + 1
                        cdefs[cdef_count] = bit_type .. ' __' .. tostring(unknown_count) .. ':' .. tostring(8 * bit_type_size - offset) .. ';'

                        diff = diff - bit_type_size
                        index = index + bit_type_size

                        offset = 0
                        bit_type = nil
                        bit_type_size = nil
                    end
                    if diff > 0 then
                        cdef_count = cdef_count + 1
                        unknown_count = unknown_count + 1
                        cdefs[cdef_count] = 'char __' .. tostring(unknown_count) .. '[' .. tostring(diff) .. '];'
                    end
                end
                index = index + diff
            end

            if is_bit then
                local bit_diff = field.offset - offset
                if bit_diff > 0 then
                    cdef_count = cdef_count + 1
                    unknown_count = unknown_count + 1
                    cdefs[cdef_count] = (bit_type or ftype.cdef) .. ' __' .. tostring(unknown_count) .. ':' .. tostring(bit_diff) .. ';'
                end
                offset = offset + bit_diff
            end

            cdef_count = cdef_count + 1
            if is_bit then
                cdefs[cdef_count] = ftype.cdef .. ' ' .. field.cname .. ':' .. tostring(ftype.bits) .. ';'
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
                cdefs[cdef_count] = (ftype.name or ftype.cdef) .. ' ' .. field.cname .. ';'

                if ftype.size ~= '*' then
                    index = index + ftype.size
                end
            end
        end

        if bit_type then
            cdef_count = cdef_count + 1
            unknown_count = unknown_count + 1
            cdefs[cdef_count] = bit_type .. ' __' .. tostring(unknown_count) .. ':' .. tostring(8 * bit_type_size - offset) .. ';'

            index = index + bit_type_size

            offset = 0
            bit_type = nil
            bit_type_size = nil
        end

        if size and index < size then
            cdef_count = cdef_count + 1
            unknown_count = unknown_count + 1
            cdefs[cdef_count] = 'char __' .. tostring(unknown_count) .. '[' .. tostring(size - index) .. ']' .. ';'
        end

        return 'struct{' .. table_concat(cdefs) .. '}', size or index
    end
end

do
    local ffi_sizeof = ffi.sizeof

    local type_mt = {
        __index = function(base, count)
            if type(count) ~= 'number' and count ~= '*' then
                return nil
            end

            return structs.array(base, count)
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
    ['bool'] = true,
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
    local ffi_metatype = ffi.metatype
    local ffi_sizeof = ffi.sizeof
    local table_sort = table.sort

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

        ftype.info = info

        return ftype
    end

    local array_metatype = function(ftype)
        local base = ftype.base
        local count = ftype.count

        ffi_metatype(ftype.name, {
            __index = function(cdata, key)
                assert(key >= 0 and key < count, 'Array index out of range (' .. tostring(key) .. '/' .. tostring(count - 1) .. ').')

                local converter = base.converter
                if converter then
                    return tolua[converter](cdata.array[key], base)
                end

                return cdata.array[key]
            end,
            __newindex = function(cdata, key, value)
                assert(key >= 0 and key < count, 'Array index out of range (' .. tostring(key) .. '/' .. tostring(count - 1) .. ').')

                local converter = base.converter
                if converter then
                    toc[converter](cdata.array, key, value, base)
                    return
                end

                cdata.array[key] = value
            end,
            __pairs = function(cdata)
                return function(arr, i)
                    i = i + 1
                    if i == count then
                        return nil, nil
                    end

                    return i, arr[i]
                end, cdata.array, -1
            end,
            __ipairs = pairs,
            __len = function(_)
                return count
            end,
        })
    end

    local struct_metatype = function(ftype)
        local fields = ftype.fields

        ffi_metatype(ftype.name, {
            __index = function(cdata, key)
                local field = fields[key]
                if not field then
                    error('Unknown field \'' .. key .. '\'.')
                end

                if field.fn then
                    return field.fn(cdata)
                end

                if field.data then
                    return field.data
                end

                local data
                do
                    local child_ftype = field.type
                    local converter = child_ftype.converter
                    data = cdata[field.cname]
                    if converter then
                        data = tolua[converter](data, child_ftype)
                    end
                end

                local lookup = field.lookup
                if not lookup then
                    return data
                end

                if type(lookup) == 'table' then
                    return lookup[data]
                end

                return lookup(data, field)
            end,
            __newindex = function(cdata, key, value)
                local field = fields[key]
                if not field then
                    error('Unknown field \'' .. key .. '\'.')
                end

                local ftype = field.type
                local converter = ftype.converter
                if converter then
                    toc[converter](cdata, field.cname, value, ftype)
                    return
                end

                cdata[field.cname] = value
            end,
            __pairs = function(cdata)
                return function(t, k)
                    local label, field = next(t, k)
                    return label, label and cdata[label]
                end, fields, nil
            end,
        })
    end

    structs.metatype = function(ftype)
        local count = ftype.count

        if count == nil then
            struct_metatype(ftype)
        elseif count ~= '*' and not ftype.info.raw_array then
            array_metatype(ftype)
        end
    end

    structs.array = function(base, count, info)
        base, count, info = info and count or base, info or count, info and base or {}

        if info.raw_array == nil then
            info.raw_array = false
        end

        local ftype = build_type(base.cdef, info)

        ftype.base = base
        ftype.count = count

        -- Cannot have VLA in a nested struct
        local raw_array = info.raw_array
        if count == '*' or raw_array then
            ftype.cdef = (base.name or base.cdef) .. '[' .. (count == '*' and '?' or count) .. ']'
            ftype.size = count == '*' and '*' or base.size * count

            structs.name(ftype, info.name, raw_array)

            return ftype
        end

        ftype.cdef = 'struct{ ' .. (base.name or base.cdef) .. ' array[' .. count .. '];}'
        ftype.size = base.size * count

        structs.name(ftype, info.name)
        structs.metatype(ftype)

        return ftype
    end

    structs.struct = function(fields, info)
        fields, info = info or fields, info and fields or {}

        local arranged = {}
        local arranged_index = 0
        for label, field in pairs(fields) do
            local ftype = field[2] or field[1]

            field.label = label
            field.type = ftype
            field.position = field[2] and field[1]
            field.offset = field.offset or 0

            if ftype then
                field.cname = (type(field.label) == 'number' or ftype.converter or field.lookup or keywords[label]) and ('_' .. tostring(label)) or label
                arranged_index = arranged_index + 1
                arranged[arranged_index] = field
            end
        end

        local first = arranged[1]
        if first and first.position then
            table_sort(arranged, function(field1, field2)
                return field1.position < field2.position or field1.position == field2.position and field1.offset < field2.offset
            end)
        end

        local cdef, size = make_struct_cdef(arranged, info.size)
        info.size = size
        local ftype = build_type(cdef, info)

        structs.name(ftype, info.name)

        local last = arranged[arranged_index]
        local last_ftype = last and last.type
        if last_ftype and last_ftype.size == '*' then
            ftype.var_size = ffi_sizeof(last_ftype.base.cdef)
            ftype.var_key = last.label
        end

        ftype.fields = fields
        ftype.arranged = arranged

        structs.metatype(ftype)

        return ftype
    end
end

do
    local ffi_cdef = ffi.cdef
    local string_sub = string.sub
    local string_gsub = string.gsub

    local declared_cache = {}
    local named_count = 0
    local package_identifier = string_gsub(windower.package_path, '%W', '')

    structs.name = function(ftype, name, raw_array)
        named_count = named_count + 1
        name = name or ftype.name
        if not name then
            name = '_gensym_' .. package_identifier .. '_' .. tostring(named_count)
        end

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
            local count = ftype.count
            if count == '*' or raw_array then
                local base = ftype.base
                ffi_cdef('typedef ' .. (base.name or base.cdef) .. ' ' .. name .. '[' .. (count == '*' and '?' or count) .. '];')
            else
                ffi_cdef('typedef ' .. ftype.cdef .. ' ' .. name .. ';')
            end
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

do
    local ffi_cast = ffi.cast

    structs.from_ptr = function(ftype, ptr)
        structs.name(ftype)
        return ffi_cast(ftype.name .. '*', ptr)[0]
    end
end

do
    local ffi_typeof = ffi.typeof

    local type_cache = {}

    structs.make = function(ftype, ...)
        local ctype = type_cache[ftype]
        if not ctype then
            ctype = ffi_typeof(ftype.name or ftype.cdef)
            type_cache[ftype] = ctype
        end

        return ctype(...)
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

local raw_array
do
    local structs_array = structs.array
    local structs_make_type = structs.make_type

    raw_array = function(cdef, count)
        return structs_array({ raw_array = true }, structs_make_type(cdef), count)
    end
end

do
    local ffi_string = ffi.string
    local ffi_copy = ffi.copy
    local string_sub = string.sub

    local string_cache = {}
    local data_cache = {}

    local make = function(size, tag, cache)
        size = size or '*'

        local ftype = cache[size]
        if not ftype then
            ftype = raw_array('char', size)
            ftype.converter = tag
            ftype.tag = tag

            string_cache[size] = ftype
        end

        return ftype
    end

    structs.string = function(size)
        return make(size, 'string', string_cache)
    end

    tolua.string = function(value, ftype)
        if ftype.size == '*' then
            return ffi_string(value)
        end

        for i = 0, ftype.size - 1 do
            if value[i] == 0 then
                return ffi_string(value, i)
            end
        end

        return ffi_string(value, ftype.size)
    end

    toc.string = function(instance, index, value, ftype)
        if ftype.size == '*' then
            ffi_copy(instance[index], value)
            return
        end

        ffi_copy(instance[index], string_sub(value, 1, ftype.size) .. '\x00')
    end

    structs.data = function(size)
        return make(size, 'data', data_cache)
    end

    tolua.data = function(value, ftype)
        return ffi_string(value, ftype.size)
    end

    toc.data = function(instance, index, value, ftype)
        ffi_copy(instance[index], value, ftype.size)
    end
end

structs.time = structs.tag(structs.uint32, 'time')
structs.time.converter = 'time'
do
    local now = os.time()
    local off = os.difftime(now, os.time(os.date('!*t', now)))

    tolua.time = function(value, ftype)
        return value + off
    end

    toc.time = function(instance, index, value, ftype)
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

    local ctype = ffi_typeof('char[?]')

    structs.packed_string = function(size, lookup_string)
        local ftype = raw_array('char', size)
        ftype.converter = 'packed_string'

        ftype.unpacked_size = math_floor(4 * size / 3)

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

    tolua.packed_string = function(value, ftype)
        local lua_lookup = ftype.lua_lookup
        local res = ctype(ftype.unpacked_size)
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

    toc.packed_string = function(instance, index, value, ftype)
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

tolua.boolbit = function(value, ftype)
    return value == 1
end

toc.boolbit = function(instance, index, value, ftype)
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
