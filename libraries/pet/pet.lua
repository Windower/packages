local client = require('shared.client')
local entities = require('entities')
local items = require('client_data.items')

local data, ftype = client.new('pet_service')



ftype.fields.target_entity = {
    get = function(data)
        return entities:by_id(data.target_id)
    end,
}


ftype.fields.automaton.type.fields.attachments.type.base.fields.item = {
    get = function(data)
        return items[data.item_id]
    end,
}

ftype.fields.automaton.type.fields.heads_available = {
    get = function(data)
        return setmetatable({}, {
            __index = function(t, k)
                return data.available_heads[k - 0x2000]
            end,
        })
    end,
}

ftype.fields.automaton.type.fields.frames_available = {
    get = function(data)
        return setmetatable({}, {
            __index = function(t, k)
                return data.available_frames[k - 0x2020]
            end,
        })
    end,
}

ftype.fields.automaton.type.fields.attach_available = {
    get = function(data)
        return setmetatable({}, {
            __index = function(t, k)
                return data.available_attach[k - 0x2100]
            end,
        })
    end,
}

return data
