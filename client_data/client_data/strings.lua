local bit = require('bit')
local entities = require('entities')
local ffi = require('ffi')
local math = require('math')
local memory = require('memory')
local resources = require('resources')
local string = require('string')
local table = require('table')
local target = require('target')
local unicode = require('unicode')
local world = require('world')
local client = require('client_data')

local strings = {}

local keys = {
    'skills',
    'elements',
    'emotes',
    'actions',
    'status_effects',
    'gameplay',
    'abilities',
    'unity',
    'zone',
}

local init
do
    local ffi_cast = ffi.cast
    local ffi_string = ffi.string
    local math_floor = math.floor
    local math_pi = math.pi
    local string_byte = string.byte
    local string_char = string.char
    local string_format = string.format
    local string_gsub = string.gsub
    local table_concat = table.concat
    local unicode_from_shift_jis = unicode.from_shift_jis

    local int_ptr = ffi.typeof('int*')
    local byte_ptr = ffi.typeof('uint8_t*')

    local lookup_data = function(category, data)
        if category == 'article' or category == 'plurality' or category == 'choice' then
            return '<' .. table_concat(data, '|') .. '>'
        end

        return ''
    end

    local lookup_fixed = function(category, data, index)
        if category == 'ignore' then
            return ''
        elseif category == 'direction' then
            return client.directions[math_floor((target.me.heading / math_pi + 1) * 4 + 1.5)].name
        end

        return '{' .. (index and index .. ':' or '') .. category .. lookup_data(category, data) .. '}'
    end

    local lookup = function(category, entity, value, data, index)
        -- print(category, value, data, index)
        if value == nil then
            return lookup_fixed(category, data, index)
        end

        if category == 'ignore' then
            return ''
        elseif category == 'entity' then
            return entity.name
        elseif category == 'spell' then
            return client.spells[value].name
        elseif category == 'ability' then
            return client.abilities[value].name
        elseif category == 'status effect' then
            return strings.status_effects[value]:string()
        elseif category == 'skill' then
            return strings.skills[value]:string()
        elseif category == 'item' then
            return client.items[value]:log_string(1)
        elseif category == 'item plural' then
            return client.items[value]:log_string(0, client.items.article.none)
        elseif category == 'key item' then
            return resources.key_items[value].name
        -- TODO
        elseif category == 'key item plural' then
            return resources.key_items[value].name
        elseif category == 'zone' then
            return client.zones[value].name
        elseif category == 'weather adjective' then
            return client.weathers[value].adjective
        elseif category == 'weather name' then
            return client.weathers[value].name
        elseif category == 'integer' then
            return tostring(value)
        elseif category == 'choice' then
            return data[value]
        -- TODO
        elseif category == 'article' then
            return data[1]
        elseif category == 'plurality' then
            return (entity or value == 1) and data[1] or data[2]
        end

        error('Unknown category "' .. category .. '".')
    end

    local parse_choices = function(ptr, origin)
        local choices = {}
        local count = 0

        local i = origin + 1
        local start = origin + 1
        while ptr[i] ~= 0x5D do
            if ptr[i] ~= 0x2F then
                i = i + 1
            else
                count = count + 1
                choices[count] = ffi_string(ptr + start, i - start)

                i = i + 1
                start = i
            end
        end

        choices[count + 1] = ffi_string(ptr + start, i - start)

        return choices, i + 1 - origin
    end

    local common0105 = function(category)
        return { category = category, parameter = 4, consume = 2, parameter_mask = 0x7F }
    end

    local lead_bytes = {
        [0x01] = {
            [0x01] = {
                sub = {
                    [0x10] = { category = 'entity', parameter = 2, parameter_mask = 0x0F, entity = true },
                    [0x00] = { category = 'ignore', consume = 2 },
                }
            },
            [0x05] = {
                [0x03] = common0105('integer'),
                [0x13] = common0105('status effect'),
                [0x17] = common0105('weather adjective'),
                [0x18] = common0105('weather name'),
                [0x23] = common0105('item'),
                [0x24] = common0105('item'),
                [0x25] = common0105('item plural'),
                [0x33] = common0105('key item'),
                [0x35] = common0105('key item plural'),
                [0x36] = common0105('key item'),
                [0x38] = common0105('zone'),
            },
            -- Like 0x05 but with two params? Possible generalization from <010101>, which has no params?
            -- [0x09] = {
            -- }
        },
        [0x05] = { category = 'skill', parameter = 1 },
        [0x0A] = { category = 'integer', parameter = 1 },
        [0x0C] = { category = 'choice', parameter = 1, parse = parse_choices },
        [0x10] = { category = 'spell', parameter = 1 },
        [0x12] = { category = 'integer', parameter = 1 },
        [0x1D] = { category = 'direction' },
        [0x7F] = {
            [0x84] = { category = 'ignore', consume = 1 },
            [0x86] = { category = 'plurality', parameter = 2, entity = false, parse = parse_choices },
            [0x87] = { category = 'plurality', parameter = 2, entity = true, parse = parse_choices },
            [0x88] = { category = 'article', parameter = 2, entity = true, parse = parse_choices },
            [0x8F] = { category = 'ability', parameter = 2 },
        },
    }

    local hex = {}
    for i = 0x00, 0xFF do
        hex[i] = string_format('<%.2X>', i)
    end
    local bit_and = bit.band

    -- TODO remove debug, optimize, but will probably need a refactoring first to account for multiple params and context-sensitive evaluation
    local evaluate = function(action, ptr, entity_ids, params)
        local tokens = {}
        local token_count = 0
        local add = function(tag, str)
            token_count = token_count + 1
            if action == 'debug' then
                str = string_gsub(str, '[^ -~]', function(c)
                    return hex[string_byte(c)]
                end)
            end
            tokens[token_count] = str
        end

        local entity_cache = {}

        local i = 0
        local start = 0
        while ptr[i] ~= 0 do
            local found = lead_bytes
            local count = 0
            repeat
                local byte = ptr[i + count]
                found = found[byte]
                count = count + 1
            until not found or found.category or found.sub

            if found then
                local sub = found.sub
                if sub then
                    local byte = ptr[i + count]
                    for high, def in pairs(sub) do
                        if bit_and(byte, 0xFC) == high then
                            found = def
                            break
                        end
                    end
                end

                local param
                local index
                local entity
                if found.parameter then
                    local byte = ptr[i + found.parameter]
                    index = (found.parameter_mask and bit_and(byte, found.parameter_mask) or byte) + 1
                    if action == 'full' then
                        if found.entity then
                            param = entity_ids[index]
                            entity = entity_cache[param]
                            if not entity then
                                entity = entities.get_by_id(param)
                                entity_cache[param] = entity
                            end
                        else
                            param = params[index]
                        end
                    end
                    count = found.parameter + 1
                end

                if found.consume then
                    count = count + found.consume
                end

                add('last', ffi_string(ptr + start, i - start))

                if action == 'debug' then
                    for j = 0, count - 1 do
                        add('pre', hex[ptr[i + j]])
                    end
                end

                local data, diff
                if found.parse then
                    data, diff = found.parse(ptr, i + count)
                    if action == 'debug' then
                        add('parse', ffi_string(ptr + i + count, diff))
                    end
                end

                if action ~= 'debug' then
                    add('meat', lookup(found.category, entity, param, data, index))
                end

                count = count + (diff or 0)
                start = i + count
            end

            i = i + count
        end

        add('trail', ffi_string(ptr + start, i - start))

        return (unicode_from_shift_jis(table_concat(tokens)))
    end

    init = function()
        if memory.string_tables.zone == nil then
            for _, name in ipairs(keys) do
                strings[name] = {}
            end
            return
        end

        for _, name in ipairs(keys) do
            local table = ffi_cast(int_ptr, memory.string_tables[name]) + 1
            local size = table[0] / 4
            strings[name] = setmetatable({}, {
                __index = function(_, id)
                    local ptr = ffi_cast(byte_ptr, table) + table[id]
                    return {
                        id = id,
                        debug = function(t)
                            return evaluate('debug', ptr)
                        end,
                        raw = function(t)
                            return evaluate('raw', ptr)
                        end,
                        string = function(t, actor, target, ...)
                            return evaluate('full', ptr, {actor, target}, {...})
                        end,
                    }
                end,
                __pairs = function(t)
                    return function(t, k)
                        k = k + 1
                        if k >= size then
                            return nil, nil
                        end

                        return k, t[k]
                    end, t, -1
                end,
                __ipairs = pairs,
                __len = function(_)
                    return size
                end,
                __newindex = error,
                __metatable = false,
            })
        end
    end
end

world.zone_change:register(function()
    init()

    coroutine.schedule(function()
        while memory.string_tables.zone == nil do
            coroutine.sleep_frame()
        end
        init()
    end)
end)

init()

return strings

--[[
Copyright © 2019, Windower Dev Team
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

