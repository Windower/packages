local math = require('math')
local table = require('table')

table.keys = function(t)
    local res = {}
    local count = 0

    for key in pairs(t) do
        count = count + 1
        res[count] = key
    end

    return res
end

do
    local prefix_search
    do
        local math_floor = math.floor

        local find_lower_bound = function(entries, prefix, index, from)
            for i = index - 1, from, -1 do
                if not entries[i]:starts_with(prefix) then
                    return i + 1
                end
            end

            return from
        end

        local find_upper_bound = function(entries, prefix, index, to)
            for i = index + 1, to, 1 do
                if not entries[i]:starts_with(prefix) then
                    return i - 1
                end
            end

            return to
        end

        prefix_search = function(entries, prefix, from, to)
            local index = math_floor((to + from) / 2)
            local entry = entries[index]
            if entry:starts_with(prefix) then
                return unpack(entries, find_lower_bound(entries, prefix, index, from), find_upper_bound(entries, prefix, index, to))
            end

            if from > to then
                return
            end

            if entry < prefix then
                return prefix_search(entries, prefix, index + 1, to)
            else
                return prefix_search(entries, prefix, from, index - 1)
            end
        end
    end

    table.prefix_search = function(t, k)
        return prefix_search(t, k, 1, #t)
    end
end

return table

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
