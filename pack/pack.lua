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
    b = {size = 0.125, type = 'number', var_size = true},
    q = {size = 0.125, type = 'boolean'},
    x = {size = 1, type = 'string', var_size = true},
}

for code, info in pairs(codes) do
    info.code = code
end

local pack_value = function(info, count, value)
    local ctype = ('%s[%i]'):format(info.ctype, info.var_size and count or 1)
    return ffi.string(ffi.new(ctype, value), ffi.sizeof(ctype))
end

local pack_bit_value = function(current, offset, info, count, value)
    if info.code == 'b' then
        return bit.bor(current, bit.lshift(bit.band(value, 2^count - 1), offset)), offset + count

    elseif info.code == 'q' then
        return bit.bor(current, value == true and 2^offset or 0), offset + 1

    end

    error('Unhandled valid code "' .. info.code .. '"')
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

string.pack = function(format, ...)
    local res = {}
    local index = 0
    local args = select('#', ...)
    local current = 0ULL
    local offset = 0

    for code, count in format:gmatch('(%a)(%d*)') do
        local info = codes[code]
        if info == nil then
            error('Unknown code \'' .. code .. '\'')
        end

        if info.var_size and count == '' then
            error('Missing length parameter for code "' .. info.code .. '"')
        end

        if offset > 0 and info.size >= 1 then
            res[#res + 1], offset, current = convert_number(current, offset, 0)
        end

        count = count ~= '' and tonumber(count) or 1

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

            if info.size < 1 then
                current, offset = pack_bit_value(current, offset, info, count, value)
            elseif info.code == 'x' then
                res[#res + 1] = value
            elseif info.code == 'S' then
                res[#res + 1] = pack_value(info, count, value .. nul:rep(count - #value))
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
    if info.ctype then
        return tonumber()

    end

    error('Unhandled valid code "' .. info.code .. '"')
end

string.unpack = function(data, format)
    local index = 1
    for code, count in format:gmatch('(%a)(%d*)') do
    end
end
