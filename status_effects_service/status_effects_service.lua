local bit = require('bit')
local os = require('os')
local pack   = require('pack')
local packet = require('packet')
local packets = require('packets')
local shared = require('shared')

status_effects = shared.new('status_effects')

local incoming = {}

status_effects.env = {
    next = next,
}

status_effects.data = {
    player = {},
    party = {},
}


incoming[0x063] = function(p)
    local packet_type = p.data:unpack('H',0x01)
    if packet_type == 9 then
        for i=1,32 do
            local buff_id = p.data:unpack('H',3+2*i)
            if buff_id == 0 or buff_id == 255 then 
                status_effects.data.player[i] = nil
            else
                status_effects.data.player[i] = {
                    id = buff_id,
                    timestamp = ((p.data:unpack('I',0x41+4*i) / 60) + 501079520 + 1009810800) - os.time()
                }
            end
        end
    end
end 

packets.incoming.register(0x076, function(p)
        local data = status_effects.data.party
        for i = 0, 4 do
            v = p.party_members[i]
            if v.id ~= 0 then
                data[i+1] = {}
                for pos = 0, 0x1F do
                    local base_value = v.status_effects[pos]
                    local mask_index = bit.rshift((pos), 2) 
                    local mask_offset = 2 * ((pos) % 4)
                    local mask_value = bit.rshift(v.status_effect_mask[mask_index], mask_offset) % 4
                    local temp = base_value + 0x100 * mask_value
                    if temp ~= 255 then
                        data[i+1][pos] = temp
                    end
                end
            end
        end
    end)

incoming.handler = function(p)
    if p.injected then return end
    
    if incoming[p.id] then 
        incoming[p.id](p)     
    end
end

packet.incoming:register(incoming.handler)