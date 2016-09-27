-- equipment_service

require('string')
read_container = require('reading')
res = read_container('resources_service')
packet = require('packet')
share_container = require('sharing')
require('pack')
bit = require('bit')

equipment = share_container()

for i=0,res.slots:len() do
    equipment[res.slots[i].en] = {bag = 'None', model = 0, bag_slot = 0, slot_id = i, encumbered=false}
end

function incoming(p)
    if p.injected then return end
    
    local function parse_inventory_chunk(data)
        local bag_slot = data:byte(1)
        local equipment_slot = res.slots[data:byte(2)].en
        local bag = res.bags[data:byte(3)].en
        
        if bag_slot == 0 then   -- Unequipping
            equipment[equipment_slot].bag = 'None'
            equipment[equipment_slot].bag_slot = 0
        else                    -- Equipping
            equipment[equipment_slot].bag = bag
            equipment[equipment_slot].bag_slot = bag_slot
        end
    end
    
    local function parse_model_chunk(data)
        -- Face               = data:byte(0x01)
        -- Race               = data:byte(0x02)
        equipment.Head.model  = data:unpack('H',0x03)
        equipment.Body.model  = data:unpack('H',0x05)
        equipment.Hands.model = data:unpack('H',0x07)
        equipment.Legs.model  = data:unpack('H',0x09)
        equipment.Feet.model  = data:unpack('H',0x0B)
        equipment.Main.model  = data:unpack('H',0x0D)
        equipment.Sub.model   = data:unpack('H',0x0F)
        equipment.Range.model = data:unpack('H',0x11)
    end
    
    if p.id == 0x00A then
        parse_model_chunk(p.data:sub(0x41,0x52))
    elseif p.id == 0x01B then
        local encumb_short = p.data:unpack('H',0x5D)
        for i=0,res.slots:len() do
            equipment[res.slots[i].en].encumbrance = (bit.band(encumb_short,2^i)~=0)
        end
    elseif p.id == 0x050 then -- /equip response
        parse_inventory_chunk(p.data)
    elseif p.id == 0x51 then
        parse_model_chunk(p.data)
    elseif p.id == 0x117 then -- /equipset response
        for i=0x45,0x81,4 do
            parse_inventory_chunk(p.data:sub(i,i+3))
        end
    end
end

packet.incoming:register(incoming)