require('string')
require('table')
require('bit')
local ffi = require('ffi')

local codes =
{
    c = {size = 1, type = 'number', ctype = 'signed char'},
    h = {size = 2, type = 'number', ctype = 'signed short'},
    i = {size = 4, type = 'number', ctype = 'signed int'},
    C = {size = 1, type = 'number', ctype = 'unsigned char'},
    H = {size = 2, type = 'number', ctype = 'unsigned short'},
    I = {size = 4, type = 'number', ctype = 'unsigned int'},
    f = {size = 4, type = 'number', ctype = 'float'},
    d = {size = 8, type = 'number', ctype = 'double'},
    B = {size = 1, type = 'boolean', ctype = 'bool'},
    S = {size = 1, type = 'string', ctype = 'char', var_size = true},
    z = {size = 1, type = 'string', ctype = 'char'},
    b = {size = 0.125, type = 'number', var_size = true},
    q = {size = 0.125, type = 'boolean'},
    x = {size = 1, type = 'string', var_size = true},
}

for code, info in pairs(codes) do
    info.code = code
end

local pack_value = function(info, count, value)
    local ctype = ('%s[%i]'):format(info.ctype, count)
    return ffi.string(ffi.new(ctype, value), ffi.sizeof(ctype))
end

local convert_number = function(number, offset, limit)
    local str = ''
    while offset > limit do
        str = str .. string.char(tonumber(number % 0x100))
        number = bit.rshift(number, 8)
        offset = offset - 8
    end

    if offset >= 0 then
        return str, offset, number
    end

    return str, 0, 0ULL
end

local nul = string.char(0)

-- TODO remove
-- string.hex = function(str)
--     local res = ''
--     local boo = false
--     for char in str:gmatch('.') do
--         if boo then
--             res = res .. ' '
--         end
--         res = res .. ('%02X'):format(char:byte())
--         boo = true
--     end
--     return res
-- end

-- require('math')
-- local bin = function(num)
--     local v = {}
--     while num > 0 do
--         v[#v + 1] = bit.band(num, 1) ~= 0 and '1' or '0'
--         num = bit.rshift(num, 1)
--     end

--     local res = '0b'
--     for i = #v, 1, -1 do
--         res = res .. v[i]
--     end
--     return res
-- end

string.pack = function(format, ...)
    local res = {}
    local index = 0
    local args = select('#', ...)
    local current = 0ULL
    local offset = 0
    local term = false

    for code, count_str in format:gmatch('(%a)(%d*)') do
        if term then
            error('Packing cannot continue after "z" code')
        end

        local info = codes[code]
        if info == nil then
            error('Unknown code \'' .. code .. '\'')
        end

        if info.var_size and count_str == '' then
            error('Missing length parameter for code "' .. info.code .. '"')
        end

        if offset > 0 and info.size >= 1 then
            res[#res + 1], offset, current = convert_number(current, offset, 0)
        end

        local count = count_str ~= '' and tonumber(count_str) or 1

        while count > 0 do
            index = index + 1
            if index > args then
                error('Bad argument #' .. tostring(index) .. ' to \'pack\' (' .. info.type .. ' expected, got no value)')
            end

            local value = select(index, ...)
            if type(value) ~= info.type then
                error('Bad argument #' .. tostring(index) .. ' to \'pack\' (' .. info.type .. ' expected, got ' .. type(value) .. ')')
            end

            if offset >= 8 then
                res[#res + 1], offset, current = convert_number(current, offset, 7)
            end

            if info.code == 'b' then
                current = bit.bor(current, bit.lshift(bit.bor(0LL, value), offset))
                offset = offset + count

            elseif info.code == 'q' then
                current = bit.bor(current, value == true and 2^offset or 0)
                offset = offset + 1

            elseif info.code == 'x' then
                res[#res + 1] = value

            elseif info.code == 'S' then
                if #value > count then
                    error('Unable to pack string ' .. value .. ' into a "' .. code .. count_str .. '" field')
                end
                res[#res + 1] = pack_value(info, count, value .. nul:rep(count - #value))

            elseif info.code == 'z' then
                if count > 1 then
                    error('Code "z" cannot appear multiple times')
                end
                res[#res + 1] = pack_value(info, #value + 1, value .. nul)
                term = true
                break

            else
                res[#res + 1] = pack_value(info, 1, value)

            end

            if info.var_size then
                break
            end

            count = count - 1
        end
    end

    if index < args then
        error('Bad argument #' .. tostring(index + 2) .. ' to \'pack\' (no value expected, got ' .. type(select(index + 2, ...)) .. ')')
    end

    if offset > 0 then
        res[#res + 1] = convert_number(current, offset, 0)
    end

    return table.concat(res)
end

local unpack_value = function(data, index, info, count)
    local ctype = ('%s[%i]'):format(info.ctype, info.var_size and count or 1)
    local size = ffi.sizeof(ctype)

    local buffer = ffi.new(ctype)
    ffi.copy(buffer, data:sub(index, index + size - 1))

    local new_index = index + size
    if info.type == 'number' then
        return tonumber(buffer[0]), new_index

    elseif info.type == 'boolean' then
        return buffer[0] == true, new_index

    elseif info.type == 'string' then
        return tostring(ffi.string(buffer, size)), new_index

    end

    error('Unhandled valid code "' .. info.code .. '"')
end

string.unpack = function(data, format)
    local res = {}
    local index = 1
    local term = false
    local offset = 0

    for code, count_str in format:gmatch('(%a)(%d*)') do
        if term then
            error('Unpacking cannot continue after "z" code')
        end

        local info = codes[code]
        if info == nil then
            error('Unknown code \'' .. code .. '\'')
        end

        if info.var_size and count_str == '' then
            error('Missing length parameter for code "' .. info.code .. '"')
        end

        if offset > 0 and info.size >= 1 then
            index = index + math.ceil(offset / 8)
            offset = 0
        end

        count = count_str ~= '' and tonumber(count_str) or 1

        if index + info.size * count > #data + 1 then
            error('Data to unpack too small for the provided format')
        end

        while count > 0 do
            while offset >= 8 do
                index = index + 1
                offset = offset - 8
            end

            if info.code == 'q' then
                res[#res + 1] = bit.band(bit.rshift(data:byte(index), offset), 0x01) == 1
                offset = offset + 1
            elseif info.code == 'b' then
                local buffer = ffi.new('uint64_t[1]')
                ffi.copy(buffer, data:sub(index, ffi.sizeof(buffer)))
                res[#res + 1] = tonumber(bit.band(bit.rshift(buffer[0], offset), 2^count - 1))
                offset = offset + count
            elseif info.code == 'x' then
                res[#res + 1] = data:sub(index, count)
                index = index + count
            elseif info.code == 'S' then
                res[#res + 1] = tostring(ffi.string(data:sub(index, index + count - 1)))
                index = index + count
            elseif info.code == 'z' then
                res[#res + 1], index = tostring(ffi.string(data:sub(index)))
                index = #data
                term = true
            else
                res[#res + 1], index = unpack_value(data, index, info, count)
            end

            if info.var_size then
                break
            end

            count = count - 1
        end
    end

    return unpack(res)
end
