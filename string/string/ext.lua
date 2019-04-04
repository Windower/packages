local string = require('string')

local string_find = string.find
local string_match = string.match
local string_rep = string.rep
local string_sub = string.sub

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

return string
