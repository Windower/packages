local channel = require('core.channel')
local client = require('shared.client')
local resources = require('resources')
local string = require('string.ext')

local string_normalize = string.normalize

local search_client = channel.get('items_service', 'items_service_search')
local search_call = search_client.call
local search_read = search_client.read

local resources_items = resources.items

local search_prefix = function(_, prefix)
    return search_prefix(prefix)
end

local data, ftype = client.new('items_service', 'items')

ftype.fields.bags.type.base.base.fields.item = {
    get = function(item_data)
        return resources_items[item_data.id]
    end,
}

ftype.fields.find_ids = {
    data = function(_, item_name)
        return search_read(search_client, 'id_map', string_normalize(item_name)) or {}
    end,
}

ftype.fields.search_inventories = {
    data = function(_, item_name)
        return search_read(search_client, 'search_map', string_normalize(item_name)) or {}
    end,
}

ftype.fields.search_prefix = {
    data = function(_, prefix)
        return search_call(search_client, search_prefix, string_normalize(prefix))
    end,
}

return data

--[[
Copyright © 2018, Windower Dev Team
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
