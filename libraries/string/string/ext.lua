local string = require('string')
local table = require('table')

local pairs = pairs
local tostring = tostring
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower
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

string.split = function(str, delim)
    local split = {}
    local split_count = 0

    local start = 1
    repeat
        local from, to = string_find(str, delim, start)
        split_count = split_count + 1
        split[split_count] = string_sub(str, start, from and from - 1)
        start = to and to + 1
    until not from

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

string.normalize = function(str)
    return (string_gsub(string_lower(str), '%W+', ''))
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
