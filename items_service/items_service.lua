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

packets.incoming[0x01C]:register(function(p)
    for i = 0, #items.data.bags do
        items.data.sizes[i] = p.size[i] - 1
    end
end)

packets.incoming[0x01E]:register(function(p)
    update_item(p.bag_id, p.bag_index, p.count, p.status)
end)

packets.incoming[0x01F]:register(function(p)
    update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id)
end)

packets.incoming[0x020]:register(function(p)
    update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id, p.bazaar, p.extdata)
end)

packets.incoming[0x050]:register(function(p)
    if p.bag_index == 0 then
        equipment.data[p.slot_id] = nil
    else
        if not items.data.bags[p.bag_id][p.bag_index] then
            items.data.bags[p.bag_id][p.bag_index] = new_item(p.bag_id, p.bag_index)
        end
        equipment.data[p.slot_id] = items.data.bags[p.bag_id][p.bag_index]
    end
end)
