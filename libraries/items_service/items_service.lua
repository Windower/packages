local account = require('account')
local channel = require('core.channel')
local client_data_items = require('client_data.items')
local math = require('math')
local packet = require('packet')
local resources = require('resources')
local server = require('shared.server')
local string = require('string.ext')
local struct = require('struct')
local table = require('table')

local item_type = struct.struct({
    id                  = {struct.int32},
    bag                 = {struct.int32},
    index               = {struct.int32},
    count               = {struct.int32},
    status              = {struct.int32},
    bazaar              = {struct.int32},
    extdata             = {struct.data(0x18)},
})

local equipment, equipment_type = server.new('equipment', struct.struct({
    slot                = {struct.int32},
    item                = {item_type},
})[16])

local bag_count = #resources.bags
local bag_size = 80

local items, items_type = server.new('items', struct.struct({
    bags                = {item_type[bag_size + 1][bag_count]},
    sizes               = {struct.int32[bag_count]},
    gil                 = {struct.int32},
}))

local items_sizes = items.sizes

local equipment_references = {}

for bag = 0, bag_count - 1 do
    for index = 0, bag_size do
        local item = items.bags[bag][index]
        item.bag = bag
        item.index = index
    end

    equipment_references[bag] = {}
end

for i = 0, 15 do
    equipment[i].slot = i
end

struct.reset_on(account.logout, equipment, equipment_type)
struct.reset_on(account.logout, items, items_type)

local search_server = channel.new('items_service_search')
search_server.data = {}
search_server.env = {}

local normalized_lookup
local init_search = function()
    normalized_lookup = {}
    search_server.data.search_map = normalized_lookup
end
init_search()

search_server.data.id_map = {}

local id_names = {}
local id_full_names = {}

do
    local string_normalize = string.normalize
    local id_map = search_server.data.id_map

    for i = 0, 0xEFFF do
        local item = client_data_items[i]
        if item ~= nil then
            local item_name = item.name
            if item_name ~= '.' then
                local name = string_normalize(item_name)
                local full_name = string_normalize(item.full_name)
                local id = item.id
                id_names[id] = name
                id_full_names[id] = full_name

                local id_map_name = id_map[name]
                if id_map_name == nil then
                    id_map_name = {}
                    id_map[name] = id_map_name
                end
                id_map_name[#id_map_name + 1] = id

                if full_name ~= name then
                    local id_map_full_name = id_map[full_name]
                    if id_map_full_name == nil then
                        id_map_full_name = {}
                        id_map[full_name] = id_map_full_name
                    end
                    id_map_full_name[#id_map_full_name + 1] = id
                end
            end
        end
    end

    do
        local math_floor = math.floor
        local table_sort = table.sort

        local name_lookup = {}
        local name_lookup_count = 0

        for key in pairs(id_map) do
            name_lookup_count = name_lookup_count + 1
            name_lookup[name_lookup_count] = key
        end

        table_sort(name_lookup)

        local binary_search
        do
            local find_lower_bound = function(prefix, index, from)
                for i = index - 1, from, -1 do
                    if not name_lookup[i]:starts_with(prefix) then
                        return i + 1
                    end
                end

                return from
            end

            local find_upper_bound = function(prefix, index, to)
                for i = index + 1, to, 1 do
                    if not name_lookup[i]:starts_with(prefix) then
                        return i - 1
                    end
                end

                return to
            end

            binary_search = function(prefix, from, to)
                local index = math_floor((to - from) / 2 + from)
                local entry = name_lookup[index]
                if entry:starts_with(prefix) then
                    return unpack(name_lookup, find_lower_bound(prefix, index, from), find_upper_bound(prefix, index, to))
                end

                if from == to then
                    return
                end

                if entry < prefix then
                    return binary_search(prefix, index + 1, to)
                else
                    return binary_search(prefix, from, index - 1)
                end
            end
        end

        local map_to_ids = function(...)
            local res = {}
            local res_count = 0

            local found = {}
            for i = 1, select('#', ...) do
                local ids = id_map[select(i, ...)]
                for j = 1, #ids do
                    local id = ids[j]
                    if found[id] == nil then
                        res_count = res_count + 1
                        res[res_count] = id
                        found[id] = true
                    end
                end
            end

            return res
        end

        search_server.env.search_prefix = function(prefix)
            return map_to_ids(binary_search(prefix, 1, name_lookup_count))
        end
    end
end

account.logout:register(init_search)

local empty_item = struct.new(item_type)

local update_item
do
    local table_remove = table.remove

    update_item = function(bag, index, count, status, id, bazaar, extdata)
        if bag == 0 and index == 0 then
            items.gil = count
            return
        end

        local item = items.bags[bag][index]
        item.count = count
        item.status = status

        if count == 0 then
            if item.id ~= 0 then
                local lookup = normalized_lookup[id_full_names[item.id]]
                if lookup ~= nil then
                    for i = 1, #lookup do
                        local entry = lookup[i]
                        if entry[1] == bag and entry[2] == index then
                            table_remove(lookup, i)
                            break
                        end
                    end
                end
            end
            item.id = 0
            item.bazaar = 0
            item.extdata = empty_item.extdata

            item = empty_item
        else
            if id then
                local old_id = item.id
                if old_id ~= id then
                    local old_lookup = normalized_lookup[id_full_names[old_id]]
                    if old_lookup ~= nil then
                        for i = 1, #old_lookup do
                            local entry = old_lookup[i]
                            if entry[1] == bag and entry[2] == index then
                                table_remove(old_lookup, i)
                                break
                            end
                        end
                    end

                    local new_name = id_full_names[id]
                    local lookup = normalized_lookup[new_name]
                    if not lookup then
                        lookup = {}
                        normalized_lookup[new_name] = lookup
                        normalized_lookup[id_names[id]] = lookup
                    end

                    lookup[#lookup + 1] = {bag, index}
                end
                item.id = id
            end
            if bazaar then
                item.bazaar = bazaar
            end
            if extdata then
                item.extdata = extdata
            end
        end

        local slot = equipment_references[bag][index]
        if slot then
            equipment[slot].item = item

            if count == 0 then
                equipment_references[bag][index] = nil
            end
        end
    end
end

packet.incoming:register_init({
    [{0x01C}] = function(p)
        for bag = 0, bag_count - 1 do
            items_sizes[bag] = p.size[bag] - 1
        end
    end,

    [{0x01E}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status)
    end,

    [{0x01F}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id)
    end,

    [{0x020}] = function(p)
        update_item(p.bag_id, p.bag_index, p.count, p.status, p.item_id, p.bazaar, p.extdata)
    end,

    [{0x050}] = function(p)
        local slot = p.slot_id
        local bag = p.bag_id
        local index = p.bag_index

        local old = equipment[slot].item
        equipment_references[old.bag][old.index] = nil
        equipment[slot].item = empty_item
        if index > 0 then
            local new = items.bags[bag][index]
            equipment[slot].item = new
            equipment_references[new.bag][new.index] = slot
        end
    end,
})

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
