local packets = require('packets')
local resources = require('resources')
local server = require('shared.server')
local structs = require('structs')
local string = require('string')

local item = structs.struct({
    id                  = {structs.int32},
    bag                 = {structs.int32},
    index               = {structs.int32},
    count               = {structs.int32},
    status              = {structs.int32},
    bazaar              = {structs.int32},
    extdata             = {structs.data(0x18)},
})

local equipment = server.new('equipment', item[16])

local bag_count = #resources.bags
local bag_size = 80

local items = server.new('items', structs.struct({
    bags                = {item[bag_size][bag_count]},
    sizes               = {structs.int32[bag_count]},
    gil                 = {structs.int32},
}))

local equipment_references = {}

for bag = 0, bag_count do
    for index = 0, bag_size do
        local item = items.bags[bag][index]
        item.bag = bag
        item.index = index
    end

    equipment_references[bag] = {}
end

local empty_item = structs.make(item)

local update_item = function(bag, index, count, status, id, bazaar, extdata)
    if bag == 0 and index == 0 then
        items.gil = count
        return
    end

    local item = items.bags[bag][index]
    item.count = count
    item.status = status

    if count == 0 then
        item.id = 0
        item.bazaar = 0
        item.extdata = empty_item.extdata
        return
    end

    if id then 
        item.id = id 
    end
    if bazaar then
        item.bazaar = bazaar
    end
    if extdata then
        item.extdata = extdata
    end

    local slot = equipment_references[bag][index]
    if slot then
        equipment[slot] = item
    end
end

packets.incoming:register_init({
    [{0x01C}] = function(p)
        for bag = 0, bag_count - 1 do
            items.sizes[bag] = p.size[bag] - 1
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
        local slot = p.slot_id
        local bag = p.bag_id
        local index = p.bag_index

        local old = equipment[slot]
        equipment_references[old.bag][old.index] = nil

        if index == 0 then
            equipment[slot] = empty_item
        else
            local new = items.bags[bag][index]
            equipment[slot] = new
            equipment_references[new.bag][new.index] = slot
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
