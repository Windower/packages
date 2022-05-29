local ffi = require('ffi')
local string = require('string')
local table = require('table')

local pairs = pairs
local tostring = tostring
local ffi_new = ffi.new
local ffi_string = ffi.string
local ffi_typeof = ffi.typeof
local string_byte = string.byte
local string_char = string.char
local string_find = string.find
local string_format = string.format
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_match = string.match
local string_rep = string.rep
local string_sub = string.sub
local table_concat = table.concat

string.starts_with = function(str, sub)
    return string_sub(str, 1, #sub) == sub
end

string.ends_with = function(str, sub)
    return string_sub(str, -#sub, #str) == sub
end

string.split = function(str, delim, max)
    local split = {}
    local split_count = 0

    local start = 1
    repeat
        local from, to = string_find(str, delim, start)
        split_count = split_count + 1
        split[split_count] = string_sub(str, start, (max == nil or split_count < max) and from and from - 1 or nil)
        start = to and to + 1
    until not from or split_count == max

    return split
end

string.trim = function(str)
    return string_match(str, '^%s*(.-)%s*$')
end

string.trim_start = function(str)
    return string_match(str, '^%s*(.-)$')
end

string.trim_end = function(str)
    return string_match(str, '^(.-)%s*$')
end

string.pad_left = function(str, count, char)
    return string_rep(char or ' ', count - #str) .. str
end

string.pad_right = function(str, count, char)
    return str .. string_rep(char or ' ', count - #str)
end

string.contains = function(str, sub)
    return string_find(str, sub, 1, true) ~= nil
end

string.index_of = function(str, sub)
    return (string_find(str, sub, 1, true))
end

string.join = function(str, enumerable)
    local values = {}
    local count = 0
    for _, value in pairs(enumerable) do
        count = count + 1
        values[count] = tostring(value)
    end

    return table_concat(values, str)
end

do
    local buffer_type = ffi_typeof('uint8_t[?]')

    local modifiers = ffi_new(buffer_type, 0x100)
    for i = 0, 0xFF do
        modifiers[i] = (i >= 0x41 and i <= 0x5A) and i + 0x20 or i
    end

    local increment = ffi_new(buffer_type, 0x100)
    for i = 0, 0xFF do
        increment[i] = (i < 0x30 or i > 0x39 and i < 0x41 or i > 0x5A and i < 0x61 or i > 0x7A and i < 0x80) and 1 or 0
    end

    local buffer = ffi_new(buffer_type, 0x100)

    string.normalize = function(str)
        local length = #str
        local offset = 0
        for i = 1, length do
            local byte = string_byte(str, i)
            buffer[i - offset - 1] = modifiers[byte]
            offset = offset + increment[byte]
        end

        return ffi_string(buffer, length - offset)
    end
end

do
    local hex = {}
    for i = 0, 0xFF do
        hex[string_char(i)] = string_format('%.2X', i)
    end

    string.hex = function(str, delim)
        if delim == nil or delim == '' then
            return (string_gsub(str, '.', hex))
        end

        local chars = {}
        local chars_count = 0
        for char in string_gmatch(str, '.') do
            chars_count = chars_count + 1
            chars[chars_count] = hex[char]
        end

        return table_concat(chars, delim)
    end
end

do
    local hex = {}
    do
        local start_digit = string_byte('0')
        local start_upper = string_byte('A')
        local start_lower = string_byte('a')

        for i = 0, 9 do
            hex[string_char(start_digit + i)] = i
        end
        for i = 0, 5 do
            hex[string_char(start_upper + i)] = 10 + i
            hex[string_char(start_lower + i)] = 10 + i
        end
    end

    string.parse_hex = function(str)
        local chars = {}
        local chars_count = 0
        local high = nil
        for char in string_gmatch(str, '.') do
            if char ~= ' ' then
                local value = hex[char]
                if high == nil then
                    high = value * 0x10
                else
                    chars_count = chars_count + 1
                    chars[chars_count] = string_char(high + value)
                    high = nil
                end
            end
        end
        return table_concat(chars)
    end
end

return string

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
