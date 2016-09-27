-- inventory_service

require('string')
require('math')
require('pack')
read_container = require('reading_lib')
res = read_container('resources_serv')
packet = require('packet')
share_container = require('sharing_lib')
bit = require('bit')

function blank_item_table(slot)
    return {id=0,
    count = 0,
    bazaar = 0,
    extdata = string.char(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    status = 0,
    bag_slot = slot}
end

inv_metatable = {}
function inv_metatable.__index(t,k)
    if tonumber(k) and k >= 0 and k <= 80 and not rawget(t,k) then
        rawset(t,k,blank_item_table(k))
    end
    return rawget(t,k)
end

function blank_inventory_table()
    return setmetatable({},inv_metatable)
end

items = share_container()

for i=0,res.bags:len() do
    items[res.bags[i].en] = blank_inventory_table()
end

equipment = {}

for i=0,res.slots:len() do
    equipment[res.slots[i].en] = {bag = 'None', bag_slot = 0}
end

function incoming(p)
    if p.injected then return end
    
    local function parse_equip_chunk(data)
        local bag_slot = data:byte(1)
        local equipment_slot = res.slots[data:byte(2)].en
        local bag = res.bags[data:byte(3)].en
        
        if bag_slot == 0 then -- Unequipping
            bag = equipment[equipment_slot].bag
            bag_slot = equipment[equipment_slot].bag_slot
            if items[bag] then -- Would not be valid for 'None'
                items[bag][bag_slot].status = 0 -- Unequipped
            end
            equipment[equipment_slot].bag = 'None'
            equipment[equipment_slot].bag_slot = 0
        else
            items[bag][bag_slot].status = 5 -- Equipped
            equipment[equipment_slot].bag = bag
            equipment[equipment_slot].bag_slot = bag_slot
        end
    end
    
    
    if p.id == 0x00B then
        items[res.bags[3].en] = blank_inventory_table()
    elseif p.id == 0x01C then
        for i=0,math.min(res.bags:len(),15) do
            items[res.bags[i].en].max = math.max(p.data:byte(i+1)-1,0)
            if res.bags[i].en ~= 'Wardrobe 3' and res.bags[i].en ~= 'Wardrobe 4' then
            -- For whatever reason, the availability of Wardrobe 3 and 4 are controlled by another packet.
                items[res.bags[i].en].enabled = p.data:unpack('H',0x11 + 2*i) > 0
            end
        end
    elseif p.id == 0x01E then
        local bag = res.bags[p.data:byte(0x05)].en
        local bag_slot = p.data:byte(0x06)
        local count = p.data:unpack('I',0x01)
        items[bag][bag_slot].count = count
        if count == 0 then
            items[bag][bag_slot].id = 0
            items[bag][bag_slot].status = 0
        else
            items[bag][bag_slot].status = p.data:byte(0x07)
        end
    elseif p.id == 0x01F then
        local bag = res.bags[p.data:byte(0x07)].en
        local bag_slot = p.data:byte(0x08)
        items[bag][bag_slot].count = p.data:unpack('I',0x01)
        items[bag][bag_slot].id = p.data:unpack('H',0x05)
        items[bag][bag_slot].status = p.data:byte(0x09)
    elseif p.id == 0x020 then
        local bag = res.bags[p.data:byte(0x0B)].en
        local bag_slot = p.data:byte(0x0C)
        items[bag][bag_slot].count = p.data:unpack('I',0x01)
        items[bag][bag_slot].bazaar = p.data:unpack('I',0x05)
        items[bag][bag_slot].id = p.data:unpack('H',0x09)
        items[bag][bag_slot].status = p.data:byte(0x0D)
        items[bag][bag_slot].extdata = p.data:sub(0x0E,0x24)
    elseif p.id == 0x037 then
        items['Wardrobe 3'].enabled = bit.band(p.data:byte(0x59),1) -- For whatever reason, this seems to be the case.
        items['Wardrobe 4'].enabled = bit.band(p.data:byte(0x59),2)
    elseif p.id == 0x050 then -- /equip response
        parse_equip_chunk(p.data)
    elseif p.id == 0x117 then -- /equipset response
        for i=0x45,0x81,4 do
            parse_equip_chunk(p.data:sub(i,i+3))
        end
    end
end

packet.incoming:register(incoming)