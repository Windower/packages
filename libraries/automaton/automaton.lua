local items = require('items')
local packet = require('packet')
local player = require('player')
local exp = require('expression')
local resources = require('resources')
local client = require('shared.client')
local enumerable = require('enumerable')

local command = require('core.command')

local data, ftype = client.new('automaton_service')

local res_items = resources.items
local assembly_offset, attachment_offset = 0x2000, 0x2100

ftype.fields.head = {
    get = function(data)
        return resources.items[data.head_id + assembly_offset]
    end
}

ftype.fields.activated ={
    get = function (data)
        return player.pet_index ~= 0 --TODO: this does not allow swapping of attachment when your automaton is not the pet you have, which is wrong.
                                     -- need to get the name of the pet and check if it matches automaton.name. getting the name seems best done a pet lib.
    end
}

ftype.fields.frame = {
     get = function(data)
        return resources.items[data.frame_id + assembly_offset]
    end
}

ftype.fields.attachments.type.base.fields.item = {
    get = function(data)
        return resources.items[data.id + attachment_offset]
    end
}

local get_attachment_id = function(attachment)
    local id = enumerable.wrap(items:find_ids(attachment)):first(exp.lookup(res_items):index('category'):is('Automaton'))
    return id and id - attachment_offset or nil
end

local get_assembly_id = function(assembly)
    local id = enumerable.wrap(items:find_ids(assembly)):first(exp.lookup(res_items):index('category'):is('Automaton'))
    return id and id - assembly_offset or nil
end

ftype.fields.validate_head = {
    data = get_assembly_id
}

ftype.fields.validate_frame = {
    data = get_assembly_id
}

ftype.fields.validate_attachment = {
    data = get_attachment_id
}

ftype.fields.deactivate = {
    data = function(_)
        command.input('/pet deactivate <me>', 'user')
    end
}

ftype.fields.activate = {
    data = function(_)
        command.input('/ja activate <me>', 'user')
    end
}

ftype.fields.remove_all = {
    data = function(_)
        local pay_load = {
            job = 0x12,
            is_sub = player.sub_job == 0x12,

            item_index = 0,
            slots = {}
        }

        for k, v in pairs(data.attachments) do
            pay_load.slots[k + 1] = v.id
        end

        packet.outgoing[0x102][0x12]:inject(pay_load)
    end,
}

ftype.fields.equip_head = {
    data = function(data, head)
        if head ~= data.head.name then
            local head_id = get_assembly_id(head)
            if player.sub_job_id ~= 0x12 and player.main_job_id ~= 0x12 then
                error('Player\'s job is not Puppetmaster!')
            end

            if head_id == nil then
                error(head .. ' is an invalid head!')
            end

            if not data.available_heads[head_id] then
                error(head .. ' is not availible!')
            end

            packet.outgoing[0x102][0x12]:inject({
                job = 0x12,
                is_sub = player.sub_job == 0x12,

                item_index = head_id,
                head = head_id
            })
        end
    end,
}

ftype.fields.equip_frame = {
    data = function(data, frame)
        if frame ~= data.frame.name then
            local frame_id = get_assembly_id(frame)
            if player.sub_job_id ~= 0x12 and player.main_job_id ~= 0x12 then
                error('Player\'s job is not Puppetmaster!')
            end

            if frame_id == nil then
                error(frame .. ' is an invalid frame!')
            end

            if not data.available_frames[frame_id - 32] then
                error(frame .. ' is not availible!')
            end

            packet.outgoing[0x102][0x12]:inject({
                job = 0x12,
                is_sub = player.sub_job == 0x12,

                item_index = frame_id,
                frame = frame_id
            })
        end
    end,
}

ftype.fields.equip_attachment = {
    data = function(data, slot, attachment)
        local attachment_id = get_attachment_id(attachment)
        if player.sub_job_id ~= 0x12 and player.main_job_id ~= 0x12 then
            error('Player\'s job is not Puppetmaster!')
        end

        if attachment_id == nil then
            error(attachment .. ' is an invalid attachment!')
        end

        if not data.available_attachments[attachment_id] then
            error(attachment .. ' is not availible!')
        end

        local payload = {
            job = 0x12,
            is_sub = player.sub_job == 0x12,

            item_index = attachment_id,
            slots = {}
        }

        payload.slots[slot] = attachment_id;
        packet.outgoing[0x102][0x12]:inject(payload)
    end,
}

return data

--[[
Copyright © 2021, Windower Dev Team
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
