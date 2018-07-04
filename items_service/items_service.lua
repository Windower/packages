local packets = require('packets')
local res = require('resources')
local shared = require('shared')

items = shared.new('items')
equipment = shared.new('equipment')

equipment.data = {}

equipment.env = {
    next = next,
}

items.data = {
    bags = {
        [0]  = { },
        [1]  = { },
        [2]  = { },
        [3]  = { },
        [4]  = { },
        [5]  = { },
        [6]  = { },
        [7]  = { },
        [8]  = { },
        [9]  = { },
        [10] = { },
        [11] = { },
        [12] = { },
    },
    sizes = {},
    gil = 0,
}

items.env = {
    next = next,
}

local new_item = function(bag, index)
    return { bag = bag, index = index }
end

local update_item = function(bag, index, count, status, id, bazaar, extdata)

    if bag == 0 and index == 0 then
        items.data.gil = count
        return
    end

    if count == 0 then
        items.data.bags[bag][index] = nil
        return
    end

    if not items.data.bags[bag][index] then 
        items.data.bags[bag][index] = new_item(bag, index)
    end

    local item = items.data.bags[bag][index]

    item.count = count
    item.status = status

    if id then 
        item.id = id 
        item.resource = res.items[id]
    end

    if bazaar then item.bazaar = bazaar end
    if extdata then item.extdata = extdata end
end

packets.incoming:register_init({
    [{0x01C}] = function(p)
        for i = 0, #items.data.bags do
            items.data.sizes[i] = p.size[i] - 1
        end
    end,

    [{0x01E}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status)
    end,

    [{0x01F}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id)
    end,

    [{0x020}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id, p.bazaar, p.extdata)
    end,

    [{0x050}] = function(p)
        if p.bag_index == 0 then
            equipment.data[p.slot_id] = nil
        else
            if not items.data.bags[p.bag_id][p.bag_index] then
                items.data.bags[p.bag_id][p.bag_index] = new_item(p.bag_id, p.bag_index)
            end
            equipment.data[p.slot_id] = items.data.bags[p.bag_id][p.bag_index]
        end
    end,
})

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
