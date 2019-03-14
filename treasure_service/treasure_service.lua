local items = require('client_data.items')
local packets = require('packets')
local server = require('shared.server')
local structs = require('structs')

local item = structs.struct({
    item_id             = {structs.uint16},
    timestamp           = {structs.time},
    player_lot          = {structs.uint32},
    highest_lot         = {structs.uint32},
    highest_lotter_id   = {structs.uint32},
    highest_lotter_name = {structs.string(0x10)},
})

local pool = server.new(item[10])

local empty = structs.make(item)

packets.incoming:register_init({
    [{0x0D2}] = function(p)
        if p.gil > 0 then
            return
        end

        local data = pool[p.pool_location]
        data.item_id = p.item_id
        data.timestamp = p.timestamp
    end,
    [{0x0D3}] = function(p)
        local drop = p.drop
        if drop == 0 then
            local data = pool[p.pool_location]
            data.highest_lot = p.highest_lot
            data.highest_lotter_id = p.highest_lotter_id
            data.highest_lotter_name = p.highest_lotter_name
        else
            pool[p.pool_location] = empty
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
