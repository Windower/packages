local bit = require('bit')
local os = require('os')
local pack   = require('pack')
local packets = require('packets')
local shared = require('shared')

status_effects = shared.new('status_effects')

status_effects.env = {
    next = next,
}

status_effects.data = {
    player = {},
    party = {},
}

packets.incoming[0x063][9]:register(function(p)
    for i = 1, 0x20 do
        local buff_id = p.status_effects[i - 1]
        if buff_id == 0 or buff_id == 0xFF then 
            status_effects.data.player[i] = nil
        else
            status_effects.data.player[i] = {
                id = buff_id,
                timestamp = (p.durations[i - 1] / 60) + 501079520 + 1009810800 - os.time()
            }
        end
    end
end)

packets.incoming[0x076]:register(function(p)
    local data = status_effects.data.party
    for i = 0, 4 do
        v = p.party_members[i]
        if v.id ~= 0 then
            data[i + 1] = {}
            for pos = 0, 0x1F do
                local base_value = v.status_effects[pos]
                local mask_index = bit.rshift((pos), 2)
                local mask_offset = 2 * (pos % 4)
                local mask_value = bit.rshift(v.status_effect_mask[mask_index], mask_offset) % 4
                local temp = base_value + 0x100 * mask_value
                if temp ~= 0xFF then
                    data[i + 1][pos] = temp
                end
            end
        end
    end
end)
