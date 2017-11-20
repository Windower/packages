--[[
enternity v1.20131102

Copyright (c) 2013, Giuliano Riccio
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of enternity nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Giuliano Riccio BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

chat = require('chat')
require('string')
bit = require('bit')

--[[blist = S{
    'Paintbrush of Souls',  -- Requires correct timing, should not be skipped
    'Geomantic Reservoir',  -- Causes dialogue freeze for some reason
}]]

function tohex(str)
    local i = 0
    local out = ''
    local key = {'1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}
    key[0] = '0'
    
    while string.len(str) > i do
        i = i + 1
        local val = str:byte(i)
        local lower4 = bit.band(val,15)
        local upper4 = bit.rshift(bit.band(val,240),4)
        out = out..key[upper4]..key[lower4]..' '
    end
    return out
end

chat.text_added:register(function(obj)
    if obj.original_type == 150 or obj.original_type == 151 then
        -- REVISIT : Might need to add exceptions for Paintbrush of Souls and Geomantic Reservoirs
        obj.text = obj.text:gsub('\u{F800}','')
    end
end)

--[[windower.register_event('incoming text', function(original, modified, mode)
    if (mode == 150 or mode == 151) then --and not original:match(string.char(0x1e, 0x02)) then
        local target = windower.ffxi.get_mob_by_target('t')
        if not (target and blist:contains(target.name)) then
            modified = modified:gsub(string.char(0x7F, 0x31), '')
        end
    end

    return modified
end)
]]
