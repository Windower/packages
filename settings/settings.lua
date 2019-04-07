local account = require('account')
local enumerable = require('enumerable')
local event = require('event')
local file = require('file')
local ffi = require('ffi')
local string = require('string')
local table = require('table')
local unicode = require('unicode')
local windower = require('windower')

ffi.cdef[[
    bool CreateDirectoryW(wchar_t*, void*);
]]

local C = ffi.C
local getmetatable = getmetatable
local pairs = pairs
local tostring = tostring
local type = type
local account_login = account.login
local account_logout = account.logout
local windower_settings_path = windower.settings_path

local info_cache = {}

local settings = {}

local get_enumerable_meta = function(t)
    return enumerable.is_enumerable(t) and getmetatable(t) or nil
end

local get_file
do
    local file_create = file.create

    local make_account_name = function(global)
        if global then
            return '[global]'
        end

        if not account.logged_in then
            return '[logged_out]'
        end

        return account.name .. '_' .. (account.server and account.server.name or account.id)
    end

    get_file = function(path, global)
        local dir = windower_settings_path .. '\\' .. make_account_name(global) .. '\\'

        C.CreateDirectoryW(unicode.to_utf16(windower_settings_path .. '\\..'), nil)
        C.CreateDirectoryW(unicode.to_utf16(windower_settings_path), nil)
        C.CreateDirectoryW(unicode.to_utf16(dir), nil)

        return file_create(dir .. path)
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
    local file_exists = file.exists
    local file_write = file.write

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

    parse = function(defaults, path, global)
        local options_file = get_file(path, global)
        local options
        if file_exists(options_file) then
            options = loadfile(options_file.path)()
        else
            file_write(options_file, 'return ' .. format_table(defaults))
            options = {}
        end

        amend(options, defaults)

        return options
    end
end

settings.load = function(defaults, path, global)
    if type(path) == 'boolean' then
        global = path
        path = nil
    end

    path = path or 'settings.lua'
    global = global ~= nil and global

    local options = parse(defaults, path, global)

    info_cache[options] = {
        path = path,
        defaults = defaults,
        global = global,
    }

    settings.save(options)
    settings.settings_change:trigger(options)

    return options
end

local save_options
do
    local file_write = file.write

    save_options = function(options, info)
        file_write(get_file(info.path, info.global), 'return ' .. format_table(options))
    end
end

settings.save = function(options)
    if options then
        save_options(options, info_cache[options])
        return
    end

    for options, info in pairs(info_cache) do
        save_options(options, info)
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
        for options, info in pairs(info_cache) do
            if not info.global then
                local parsed = parse(info.defaults, info.path)
                update(options, parsed)
                settings.save(options)
                settings.settings_change:trigger(options)
            end
        end
    end

    account_login:register(reparse)
    account_logout:register(reparse)
end

settings.settings_change = event.slim.new()

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
