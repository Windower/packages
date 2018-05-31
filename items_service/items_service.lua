local shared = require('shared')
local packets = require('packets')
local res = require('resources')
require('pack')

items = shared.new('items')
equipment = shared.new('equipment')

equipment.data = {}

equipment.env = {
    next = next,
    pairs = pairs,
    type = type,
}

items.data = {
    bags = {
        [0]  = { size = 0, contents = {} },
        [1]  = { size = 0, contents = {} },
        [2]  = { size = 0, contents = {} },
        [3]  = { size = 0, contents = {} },
        [4]  = { size = 0, contents = {} },
        [5]  = { size = 0, contents = {} },
        [6]  = { size = 0, contents = {} },
        [7]  = { size = 0, contents = {} },
        [8]  = { size = 0, contents = {} },
        [9]  = { size = 0, contents = {} },
        [10] = { size = 0, contents = {} },
        [11] = { size = 0, contents = {} },
        [12] = { size = 0, contents = {} },
    },
    gil = 0,
}

items.env = {
    next = next,
    pairs = pairs,
    table = table,
    type = type,
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
        items.data.bags[bag].contents[index] = nil
        return
    end

    if not items.data.bags[bag].contents[index] then 
        items.data.bags[bag].contents[index] = new_item(bag, index)
    end

    local item = items.data.bags[bag].contents[index]

    item.count = count
    item.status = status

    if id then 
        item.id = id 
        item.resource = res.items[id]
    end

    if bazaar then item.bazaar = bazaar end
    if extdata then item.extdata = extdata end
end

local item_handlers = {
    [0x01C] = function(data)
        for i = 0, #items.data.bags do
            items.data.bags[i].size = data:byte(0x01 + i) - 1
        end
    end,

    [0x01E] = function(data)
        local count = data:unpack('I', 0x01)
        local bag = data:unpack('C', 0x05)
        local index = data:unpack('C', 0x06)
        local status = data:unpack('C', 0x07)
        update_item(bag, index, count, status)
    end,

    [0x01F] = function(data)
        local count = data:unpack('I', 0x01)
        local item = data:unpack('H', 0x05)
        local bag = data:unpack('C', 0x07)
        local index = data:unpack('C', 0x08)
        local status = data:unpack('C', 0x09)
        update_item(bag, index, count, status, item)
    end,

    [0x020] = function(data)
        local count = data:unpack('I', 0x01)
        local bazaar = data:unpack('I', 0x05)
        local id = data:unpack('H', 0x09)
        local bag = data:unpack('C', 0x0B)
        local index = data:unpack('C', 0x0C)
        local status = data:unpack('C', 0x0D)
        local extdata = data:unpack('S24', 0x0E)
        update_item(bag, index, count, status, id, bazaar, extdata)
    end,
}

packets.incoming:register(function(p)
    if p.injected then
        return
    end

    if item_handlers[p.id] then
        item_handlers[p.id](p.data)
    end
end)

packets.incoming:register(0x050, function(p)
    if p.inventory_index == 0 then
        equipment.data[p.slot_id] = nil
    else
        if not items.data.bags[p.bag_id].contents[p.inventory_index] then
            items.data.bags[p.bag_id].contents[p.inventory_index] = new_item(p.bag_id, p.inventory_index)
        end
        equipment.data[p.slot_id] = items.data.bags[p.bag_id].contents[p.inventory_index]
    end
end)
