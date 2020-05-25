local event = require('core.event')
local packet = require('packet')
local server = require('shared.server')
local struct = require('struct')

local item_type = struct.struct({
    item_id             = {struct.uint16},
    timestamp           = {struct.time()},
    player_lot          = {struct.uint32},
    highest_lot         = {struct.uint32},
    highest_lotter_id   = {struct.uint32},
    highest_lotter_index= {struct.uint16},
    highest_lotter_name = {struct.string(0x10)},
})

local data = server.new(struct.struct({
    pool                = {item_type[10]},
    item_found          = {data = event.new()},
    item_lotted         = {data = event.new()},
    item_dropped        = {data = event.new()},
}))

local pool = data.pool
local item_found = data.item_found
local item_lotted = data.item_lotted
local item_dropped = data.item_dropped

local empty = struct.new(item_type)

local drop_types = {
    [0] = 'lot',
    [1] = 'win',
    [2] = 'loss',
    [3] = 'drop',
}

packet.incoming:register_init({
    [{0x0D2}] = function(p)
        if p.gil > 0 then
            return
        end

        if p.item_id == 0 then
            pool[p.pool_index] = empty
        else
            local data_slot = pool[p.pool_index]
            data_slot.item_id = p.item_id
            data_slot.timestamp = p.timestamp

            item_found:trigger({
                pool_index = p.pool_index,
                dropper_id = p.dropper_id,
                is_old = p.is_old,
            })
        end
    end,
    [{0x0D3}] = function(p)
        local drop = p.drop
        if drop == 0 then
            local data_slot = pool[p.pool_index]
            data_slot.highest_lot = p.highest_lot
            data_slot.highest_lotter_id = p.highest_lotter_id
            data_slot.highest_lotter_index = p.highest_lotter_index
            data_slot.highest_lotter_name = p.highest_lotter_name
            item_lotted:trigger({
                pool_index = p.pool_index,
                lotter_id = p.lotter_id,
                lotter_index = p.lotter_index,
                lotter_name = p.lotter_name,
                lot = p.lot,
            })
        else
            local item = pool[p.pool_index]
            local event_arg = {
                type = drop_types[drop],
                item_id = item.item_id,
                winner_id = item.highest_lotter_id,
                winner_index = item.highest_lotter_index,
                winner_name = item.highest_lotter_name,
            }
            pool[p.pool_index] = empty
            item_dropped:trigger(event_arg)
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
