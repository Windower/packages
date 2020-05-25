local package_name = package.name
if package_name == nil then
    error('Cannot load the settings library in the script environment.')
end

local account = require('account')
local client = require('shared.client')
local enumerable = require('enumerable')
local event = require('core.event')
local file = require('file')
local ffi = require('ffi')
local channel = require('core.channel')
local string = require('string.ext')
local table = require('table')
local unicode = require('core.unicode')
local windower = require('core.windower')

ffi.cdef[[
    bool CreateDirectoryW(wchar_t*, void*);
]]

local C = ffi.C
local error = error
local getmetatable = getmetatable
local loadstring = loadstring
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local account_login = account.login
local account_logout = account.logout
local unicode_to_utf16 = unicode.to_utf16
local windower_settings_path = windower.settings_path

local info_cache = {}

local settings = {}

local get_enumerable_meta = function(t)
    return enumerable.is_enumerable(t) and getmetatable(t) or nil
end

local get_file
do
    local file_new = file.new

    local make_account_name = function(global)
        if global then
            return '[global]'
        end

        if not account.logged_in then
            return '[logged_out]'
        end

        return account.name .. '_' .. (account.server and account.server.name or account.id)
    end

    get_file = function(id, global)
        local dir = windower_settings_path .. '\\' .. make_account_name(global)

        C.CreateDirectoryW(unicode_to_utf16(windower_settings_path .. '\\..'), nil)
        C.CreateDirectoryW(unicode_to_utf16(windower_settings_path), nil)
        C.CreateDirectoryW(unicode_to_utf16(dir), nil)

        return file_new(dir .. '\\' .. id .. '.lua')
    end
end

local format_table
do
    local string_match = string.match
    local string_rep = string.rep
    local table_concat = table.concat

    local format_key = function(key)
        if type(key) == 'string' then
            return string_match(key, '^%a[%w_]*$') or '[\'' .. key .. '\']'
        else
            return '[' .. tostring(key) .. ']'
        end
    end

    local format_value = function(value, nested)
        local value_type = type(value)
        if value_type == 'table' then
            return format_table(value, nested + 1)
        elseif value_type == 'string' then
            return '\'' .. value .. '\''
        else
            return tostring(value)
        end
    end

    format_table = function(t, nested)
        nested = nested or 1

        local indent = string_rep('    ', nested)

        local res = {}
        res[1] = '{'

        local count = 1

        local meta = get_enumerable_meta(t)
        if meta ~= nil then
            for _, value in pairs(t) do
                count = count + 1
                res[count] = indent .. format_value(value, nested) .. ','
            end
        else
            for key, child in pairs(t) do
                count = count + 1
                res[count] = indent .. format_key(key) .. ' = ' .. format_value(child, nested) .. ','
            end
        end

        res[count + 1] = string_rep('    ', nested - 1) .. '}'

        local joined = table_concat(res, '\n')
        if nested > 1 then
            return joined
        end

        return joined .. '\n'
    end
end

local parse
do
    local amend
    amend = function(parsed, defaults)
        for key, value in pairs(defaults) do
            local parsed_child = parsed[key]
            if type(value) == 'table' then
                local meta = get_enumerable_meta(value)
                if meta ~= nil then
                    parsed[key] = meta.__convert(parsed_child == nil and value or parsed_child)
                else
                    if parsed_child == nil then
                        parsed_child = {}
                        parsed[key] = parsed_child
                    end

                    amend(parsed_child, value)
                end
            elseif parsed_child == nil then
                parsed[key] = value
            end
        end
    end

    parse = function(defaults, id, global)
        local options_file = get_file(id, global)
        local options
        if options_file:exists() then
            options = loadstring(options_file:read())()
        else
            options_file:write('return ' .. format_table(defaults))
            options = {}
        end

        amend(options, defaults)

        return options
    end
end

settings.load = function(defaults, id, global)
    if type(id) == 'boolean' then
        global = id
        id = nil
    end

    id = id or 'settings'
    global = global ~= nil and global

    local options = parse(defaults, id, global)

    info_cache[id] = {
        id = id,
        defaults = defaults,
        global = global,
        options = options,
    }

    settings.save(id)
    settings.settings_change:trigger(options)

    return options
end

do
    settings.save = function(id)
        local info = info_cache[id or 'settings']
        get_file(info.id, info.global):write('return ' .. format_table(info.options))
    end
end

do
    local update
    update = function(current, parsed)
        if not current then
            return parsed
        end

        for key, value in pairs(parsed) do
            if type(value) == 'table' then
                local current_table = current[key]
                local meta = get_enumerable_meta(current_table)
                if meta ~= nil then
                    current_table:clear()
                    for k, v in pairs(value) do
                        current_table:add(v, k)
                    end
                else
                    current[key] = update(current[key], value)
                end
            else
                current[key] = value
            end
        end

        for key in pairs(current) do
            if parsed[key] == nil then
                current[key] = nil
            end
        end

        return current
    end

    local reparse = function()
        for id, info in pairs(info_cache) do
            if not info.global then
                local options = info.options
                local parsed = parse(info.defaults, info.id)

                update(options, parsed)

                settings.save(id)
                settings.settings_change:trigger(options)
            end
        end
    end

    account_login:register(reparse)
    account_logout:register(reparse)
end

settings.settings_change = event.new()

settings.get = function(path, id)
    local setting = info_cache[id or 'settings'].options

    local tokens = path:split('%.')
    for i = 1, #tokens do
        setting = setting[tokens[i]]
    end

    return setting
end

do
    local string_sub = string.sub

    local parse_value = function(value)
        if value == 'true' then
            return true
        elseif value == 'false' then
            return false
        elseif value == 'nil' then
            return nil
        end

        local quote = string_sub(value, 1, 1)
        if (quote == '\'' or quote == '"') and quote == string_sub(value, -1, -1) then
            return string_sub(value, 2, -2)
        end

        local number = tonumber(value)
        if number then
            return number
        end

        error('Unknown parameter')
    end

    settings.set = function(path, value, id)
        local setting_container = info_cache[id or 'settings'].options

        local tokens = path:split('%.')
        local length = #tokens
        for i = 1, length - 1 do
            setting_container = setting_container[tokens[i]]
        end

        local setting = parse_value(value)
        setting_container[tokens[length]] = setting

        return setting
    end
end

do
    local data = client.new('settings_service')
    local query_client = channel.get('settings_service', 'query')

    local query_response = function(_, path, setting)
        query_response(path, setting)
    end

    data.get:register(function(addon, path, id)
        if addon ~= package_name then
            return
        end

        local setting = settings.get(path, id)

        query_client:call(query_response, path, setting)
    end)

    data.set:register(function(addon, path, value, id)
        if addon ~= package_name then
            return
        end

        local setting = settings.set(path, value, id)
        settings.save(id)

        query_client:call(query_response, path, setting)
    end)
end

return settings

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
