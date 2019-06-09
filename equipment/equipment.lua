local client = require('shared.client')
local resources = require('resources')
local packets = require('packets')

local data, ftype = client.new('items_service', 'equipment')

ftype.base.fields.item.type.fields.item = {
    get = function(data)
        return resources.items[data.id]
    end,
}

ftype.base.fields.equip = {
    data = function(equipment_slot, item)
        local bag = item.bag
        local index = item.index
        assert(resources.bags[bag].equippable, "Can not equip from this bag (bag = " .. bag .. ")")
        assert(item.id ~= 0, "Can not equip from an empty bag slot (bag = " .. bag .. ", index = " .. index .. ")")

        packets.outgoing[0x050]:inject({bag_index = index, slot_id = equipment_slot.slot, bag_id = bag})
    end,
}

ftype.base.fields.unequip = {
    data = function(equipment_slot)
        packets.outgoing[0x050]:inject({bag_index = 0, slot_id = equipment_slot.slot, bag_id = 0})
    end,
}

local equipment = {}

equipment.equip = function(slot_items)
    local count = 0
    local items = {}
    for slot, item in pairs(slot_items) do
        if slot >= 0 and slot <= 15 then
            local bag = item and item.bag or 0
            local index = item and item.index or 0
            assert(resources.bags[bag].equippable, "Can not equip from this bag (bag = " .. bag .. ")")
            assert(not item or item.id ~= 0, "Can not equip from an empty bag slot (bag = " .. bag .. ", index = " .. index .. ")")
            items[count] = {bag_index = index, slot_id = slot, bag_id = bag}
            count = count + 1
        end
    end

    packets.outgoing[0x051]:inject({count = count, equipment = items})
end

local slot_names = {
    main = 0, sub = 1, range = 2, ammo = 3,
    head = 4, neck = 9, ear1 = 11, ear2 = 12,
    body = 5, hands = 6, ring1 = 13, ring2 = 14,
    back = 15, waist = 10, legs = 7, feet = 8,
}

local equipment_mt = {
    __index = function(t, k)
        local index = slot_names[k] or k
        return data[index]
    end,
    __newindex = function(t, k, v)
        local index = slot_names[k] or k
        data[index] = v
    end,
    __pairs = function(t)
        return pairs(data)
    end,
    __ipairs = function(t)
        return ipairs(data)
    end,
    __len = function(t)
        return #data
    end
}

return setmetatable(equipment, equipment_mt)

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
