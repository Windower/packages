local bit = require('bit')
local ffi = require('ffi')
local string = require('string')
local table = require('table')

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

string.pack = function(format, ...)
    local res = {}
    local index = 0
    local args = select('#', ...)
    local current = 0ULL
    local offset = 0
    local term = false

    for code, count_str in format:gmatch('(%a)(%d*)') do
        assert(not term, 'Packing cannot continue after "z" code')

        local info = codes[code]
        assert(info ~= nil, 'Unknown code \'' .. code .. '\'')

        assert(not info.var_size or count_str ~= '', 'Missing length parameter for code "' .. info.code .. '"')

        if offset > 0 and info.size >= 1 then
            res[#res + 1], offset, current = convert_number(current, offset, 0)
        end

        local count = count_str ~= '' and tonumber(count_str) or 1

        while count > 0 do
            index = index + 1
            assert(index <= args, 'Bad argument #' .. tostring(index + 1) .. ' to \'pack\' (' .. info.type .. ' expected, got no value)')

            local value = select(index, ...)
            assert(type(value) == info.type, 'Bad argument #' .. tostring(index + 1) .. ' to \'pack\' (' .. info.type .. ' expected, got ' .. type(value) .. ')')

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
                assert(#value <= count, 'Unable to pack string ' .. value .. ' into a "' .. code .. count_str .. '" field')
                res[#res + 1] = pack_value(info, count, value .. nul:rep(count - #value))

            elseif info.code == 'z' then
                assert(count <= 1, 'Code "z" cannot appear multiple times')
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

    assert(index >= args, 'Bad argument #' .. tostring(index + 2) .. ' to \'pack\' (no value expected, got ' .. type(select(index + 1, ...) or nil) .. ')')

    if offset > 0 then
        res[#res + 1] = convert_number(current, offset, 0)
    end

    return table.concat(res)
end

local cstring = ffi.typeof('char const*')
local unpack_value = function(data, index, info, count)
    local ctype = ('%s[%i]'):format(info.ctype, info.var_size and count or 1)
    local size = ffi.sizeof(ctype)

    local buffer = ffi.new(ctype)
    local cstr = cstring(data)
    ffi.copy(buffer, cstr + index - 1, size)

    local new_index = index + size
    if info.type == 'number' then
        return tonumber(buffer[0]), new_index

    elseif info.type == 'boolean' then
        return buffer[0] == true, new_index

    end

    error('Unhandled valid code "' .. info.code .. '"')
end

string.unpack = function(data, format, index, offset)
    index = index or 1
    offset = offset or 0

    local res = {}
    local term = false
    for code, count_str in format:gmatch('(%a)(%d*)') do
        assert(not term, 'Unpacking cannot continue after "z" code')

        local info = codes[code]
        assert(info ~= nil, 'Unknown code \'' .. code .. '\'')

        assert(not info.var_size or count_str ~= '', 'Missing length parameter for code "' .. info.code .. '"')

        if offset > 0 and info.size >= 1 then
            index = index + math.ceil(offset / 8)
            offset = 0
        end

        local count = count_str ~= '' and tonumber(count_str) or 1

        assert(index + info.size * count <= #data + 1, 'Data to unpack too small for the provided format')

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
                res[#res + 1] = tostring(ffi.string(data:sub(index)))
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
