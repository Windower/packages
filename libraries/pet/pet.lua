local table = require('table')

local client = require('shared.client')
local entities = require('entities')
local items = require('client_data.items')


local data, ftype = client.new('pet_service')

ftype.fields.target_entity = {
    get = function(data)
        return entities:by_id(data.target_id)
    end,
}

ftype.fields.automaton.type.fields.equipment.type.fields.head = {
    get = function(data)
        return items[data.head_id]
    end,
}

ftype.fields.automaton.type.fields.equipment.type.fields.frame = {
    get = function(data)
        return items[data.frame_id]
    end,
}

ftype.fields.automaton.type.fields.equipment.type.fields.attachments = {
    get = function(data)
        return setmetatable({}, {
            __index = function(t, k)
                local item_id = data.attachment_ids[k]
                if item_id == 0 then
                    return nil
                else
                    return items[data.attachment_ids[k]]
                end
            end,
        })
    end,
}

ftype.fields.automaton.type.fields.inventory.type.fields.heads = {
    get = function(data)
        local t = {}
        local i
        for i = 0, 8 do
            if data.automaton.inventory._heads[i] then
                table:append(t,items[i+0x2000])
            end
        end
    end
}

ftype.fields.automaton.type.fields.inventory.type.fields.heads = {
    get = function(data)
        local t = {}
        local i
        for i = 0, 21 do
            if data.automaton.inventory._heads[i] then
                table:append(t,items[i+0x2020])
            end
        end
    end
}

ftype.fields.automaton.type.fields.inventory.type.fields.heads = {
    get = function(data)
        local t = {}
        local i
        for i = 0, 31 do
            if data.automaton.inventory._heads[i] then
                table:append(t,items[i+0x2020])
            end
        end
    end
}

ftype.fields.automaton.type.fields.inventory.type.fields.attachments = {
    get = function(data)
        local t = {}
        local i
        for i = 0, 255 do
            if data.automaton.inventory._attachments[i] then
                table:append(t,items[i+0x2100])
            end
        end
    end
}

ftype.fields.automaton.type.fields.inventory.type.fields.has_head = {
    data = function(_, item)
        local id = nil
        if type(item) == 'number' then
            id = item
        elseif type(item) == 'table' and item.id then
            id = item.id
        end
        if id and id >= 0x2000 and id < 0x2020 then
            return data.automaton.inventory._heads[id-0x2000]
        end
        return nil
    end,
}

ftype.fields.automaton.type.fields.inventory.type.fields.has_frame = {
    data = function(_, item)
        local id = nil
        if type(item) == 'number' then
            id = item
        elseif type(item) == 'table' and item.id then
            id = item.id
        end
        if id and id >= 0x2020 and id < 0x2040 then
            return data.automaton.inventory._frames[id-0x2020]
        end
        return nil
    end,
}

ftype.fields.automaton.type.fields.inventory.type.fields.has_attachment = {
    data = function(_, item)
        local id = nil
        if type(item) == 'number' then
            id = item
        elseif type(item) == 'table' and item.id then
            id = item.id
        end
        if id and id >= 0x2100 and id < 0x2200 then
            return data.automaton.inventory._attachments[id-0x2100]
        end
        return false
    end,
}

return data

--[[
Copyright © 2020, Windower Dev Team
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
