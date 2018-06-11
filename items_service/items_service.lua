local shared = require('shared')
local packets = require('packets')
local res = require('resources')

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

packets.incoming.register(0x01C, function(p)
    for i = 0, #items.data.bags do
        items.data.bags[i].size = p.size[i] - 1
    end
end)

packets.incoming.register(0x01E, function(p)
    update_item(p.bag, p.bag_index, p.count, p.status)
end)

packets.incoming.register(0x01F, function(p)
    update_item(p.bag, p.bag_index, p.count, p.status, p.item_id)
end)

packets.incoming.register(0x020, function(p)
    update_item(p.bag, p.bag_index, p.count, p.status, p.item_id, p.bazaar, p.extdata)
end)

packets.incoming.register(0x050, function(p)
    if p.bag_index == 0 then
        equipment.data[p.slot_id] = nil
    else
        if not items.data.bags[p.bag_id].contents[p.bag_index] then
            items.data.bags[p.bag_id].contents[p.bag_index] = new_item(p.bag_id, p.bag_index)
        end
        equipment.data[p.slot_id] = items.data.bags[p.bag_id].contents[p.bag_index]
    end
end)
