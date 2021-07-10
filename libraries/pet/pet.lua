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

--[[
Copyright © 2020, John S Hobart
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