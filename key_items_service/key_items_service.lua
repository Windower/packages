local bit = require('bit')
local packet = require('packet')
local server = require('shared.server')
local string = require('string')
local struct = require('struct')

local type_size = 0x200
local type_count = 8

local key_item = struct.struct({
    id                  = {struct.uint32},
    available           = {struct.bool},
    examined            = {struct.bool},
})

local key_items = server.new('key_items', key_item[type_count * type_size])

for i = 0, type_count * type_size - 1 do
    key_items[i].id = i
end

local bit_band = bit.band
local bit_lshift = bit.lshift
local string_byte = string.byte

packet.incoming:register_init({
    [{0x055}] = function(p)
        local offset = p.type * type_size
        local available = p.key_items_available
        local examined = p.key_items_examined

        for i = 0, 0x1FF do
            local ki = key_items[i + offset]

            local index = (i / 8) + 1
            local mask = bit_lshift(1, i % 8)
            ki.available = bit_band(string_byte(available, index), mask) ~= 0
            ki.examined = bit_band(string_byte(examined, index), mask) ~= 0
        end
    end,
})

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
