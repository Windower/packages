local ffi = require('ffi');
require('bit')
require('string')
require('os')
require('math')
require('table')
require('pack')

local structs = {}

structs.copy_type = function(base)
    local new = structs.make_type(base.cdef)

    for key, value in pairs(base) do
        new[key] = value
    end

    return new
end

local make_cdef = function(arranged)
    local cdefs = {}
    local index = 0x00
    local offset = 0
    local bit_type
    local unknown_count = 1
    for _, field in ipairs(arranged) do
        -- Can only happen with char*, should only appear at the end
        if field.type.cdef == nil then
            break;
        end

        local is_bit = field.type.bits ~= nil

        local diff = field.position - index
        if diff > 0 then
            cdefs[#cdefs + 1] = ('char _unknown%u[%u]'):format(unknown_count, diff)
            unknown_count = unknown_count + 1
        end
        index = index + diff

        if is_bit then
            if bit_type ~= nil then
                assert(field.type.cdef == bit_type, 'Bit field must have the same base types for every member.')
            end
            local bit_diff = field.offset - offset
            if bit_diff > 0 then
                cdefs[#cdefs + 1] = ('%s _unknown%u:%u'):format(bit_type or field.type.cdef, unknown_count, bit_diff)
                unknown_count = unknown_count + 1
            end
            offset = offset + bit_diff
        elseif bit_type ~= nil then
            local bit_diff = field.offset - offset
            if bit_diff > 0 then
                cdefs[#cdefs + 1] = ('%s _unknown%u:%u'):format(bit_type, unknown_count, bit_diff)
                unknown_count = unknown_count + 1
            end
            offset = 0
            bit_type = nil
        end

        if is_bit then
            cdefs[#cdefs + 1] = ('%s %s:%u'):format(field.type.cdef, field.cname, field.type.bits)
            offset = offset + field.type.bits
            if offset == 8 * field.type.size then
                offset = 0
                bit_type = nil
            else
                bit_type = field.type.cdef
            end
        else
            if field.type.count ~= nil then
                cdefs[#cdefs + 1] = ('%s %s[%u]'):format(field.type.cdef, field.cname, field.type.count)
            elseif field.type.ptr == true then
                cdefs[#cdefs + 1] = ('%s* %s'):format(field.type.cdef, field.cname)
            else
                cdefs[#cdefs + 1] = ('%s %s'):format(field.type.cdef, field.cname)
            end
            index = index + field.type.size
        end
    end

    return ('struct{%s;}'):format(table.concat(cdefs, ';'))
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

        local new = structs.copy_type(base)

        new.count = count
        new.size = count * base.size
        new.base = base

        return new
    end,
}

structs.make_type = function(cdef)
    return setmetatable({
        cdef = cdef,
        size = ffi.sizeof(cdef),
    }, type_mt)
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

structs.struct = function(fields)
    local arranged = {}
    for label, data in pairs(fields) do
        local full = {
            label = label,
            cname = keywords[label] ~= nil and ('_%s'):format(label) or label,
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

    local new = structs.copy_type({cdef = make_cdef(arranged)})
    new.fields = arranged

    return new
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
        return { tag = 'string' }
    end

    if not string_types[length] then
        local new = structs.make_type('char')[length]

        new.tolua = function(raw)
            return ffi.string(raw)
        end

        new.toc = function(str)
            return #str >= length and str:sub(0, length) or str .. ('\0'):rep(length - #str)
        end

        string_types[length] = new
    end

    return string_types[length]
end

local data_types = {}

structs.data = function(length)
    if not data_types[length] then
        local new = structs.make_type('char')[length]

        new.tolua = function(raw)
            return ffi.string(raw, length)
        end

        new.toc = function(str)
            return #str >= length and str:sub(0, length) or str .. ('\0'):rep(length - #str)
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

    structs.time.tolua = function(ts)
        return ts + off
    end

    structs.time.toc = function(ts)
        return ts - off
    end
end

structs.encoded = function(size, bits, lookup_string)
    local new = structs.make_type('char')[size]
    local pack_str = ('b%u'):format(bits):rep(math.floor(8 * size / bits))

    local lua_lookup = {}
    do
        local index = 0
        for char in lookup_string:gmatch('.') do
            lua_lookup[index] = char
            index = index + 1
        end
    end

    local c_lookup = {}
    for i, v in pairs(lua_lookup) do
        c_lookup[v] = i
    end

    new.tolua = function()
        return function(value)
            local res = {}
            for i, v in ipairs({value:unpack(pack_str)}) do
                res[i] = lua_lookup[v]
            end
            return table.concat(res)
        end
    end

    new.toc = function()
        return function(value)
            local res = {}
            local index = 0
            for c in value:gmatch('.') do
                res[index] = c_lookup[c]
                index = index + 1
            end
            return pack_str:pack(unpack(res))
        end
    end

    return new
end

structs.bit = function(base, bits)
    local new = structs.copy_type(base)

    new.bits = bits

    return new
end

structs.boolbit = function(base, bits)
    local new = structs.bit(base, bits or 1)

    if bits ~= nil then
        new.tolua = function(value)
            local res = {}
            for i = 1, bits do
                res[i] = bit.band(bit.rshift(value, i - 1), 1) == 1
            end
            return res
        end

        new.toc = function(value)
            local res = 0
            for i, v in pairs(value) do
                if v then
                    res = bit.bor(res, bit.lshift(1, i - 1))
                end
            end
            return res
        end
    else
        new.tolua = function(value)
            return value == 1
        end

        new.toc = function(value)
            return value and 1 or 0
        end
    end

    return new
end

structs.ptr = function(base)
    local new = structs.copy_type(base)

    new.ptr = true
    new.size = ffi.sizeof('void*')

    return new
end

return structs
