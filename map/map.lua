local ffi = require('ffi')
local memory = require('memory')
local scanner = require('scanner')
local world = require('world')

ffi.cdef[[
    typedef int (__fastcall *map_fn)(void*, int, float, float, float);
]]

local fn = ffi.cast('map_fn', scanner.scan('&8B542408568D4424108BF18B4C2410508B44240C'))
local this = ffi.cast('void**', scanner.scan('8B7424148B4424108B7C240C8B0D'))[0]

return {
    map = function(x, y, z)
        return fn(this, 0, x, z, y)
    end,
    data = function(map_id)
        local zone_id = world.zone_id
        local ptr = memory.map_table.ptr
        local count = 0
        while ptr[count].zone_id ~= zone_id do
            count = count + 1
        end

        while ptr[count].map_id ~= map_id do
            count = count + 1
        end

        return ptr[count]
    end,
}

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
