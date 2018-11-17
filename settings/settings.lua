local account = require('account')
local event = require('event')
local files = require('files')
local ffi = require('ffi')
local string = require('string')
local table = require('table')
local unicode = require('unicode')
local windower = require('windower')

ffi.cdef[[
    bool CreateDirectoryW(wchar_t*, void*);
]]

local C = ffi.C

local info_cache = {}

local settings = {}

local get_file
do
    local make_account_name = function()
        if not account.logged_in then
            return 'logged_out'
        end

        return account.name .. '_' .. (account.server and account.server.name or account.id)
    end

    get_file = function(path, global)
        local dir = windower.settings_path .. '\\' .. (global and '[global]' or make_account_name()) .. '\\'

        C.CreateDirectoryW(unicode.to_utf16(windower.settings_path .. '\\..'), nil)
        C.CreateDirectoryW(unicode.to_utf16(windower.settings_path), nil)
        C.CreateDirectoryW(unicode.to_utf16(dir), nil)

        return files.create(dir .. path)
    end
end

local format_table
do
    local format_key = function(key)
        if type(key) == 'string' then
            return key:match('^%a[%w_]*$') or '[\'' .. key .. '\']'
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

        local indent = ('    '):rep(nested)

        local res = {}
        res[1] = '{'

        local count = 1
        for key, child in pairs(t) do
            count = count + 1
            res[count] = indent .. format_key(key) .. ' = ' .. format_value(child, nested) .. ','
        end

        res[count + 1] = ('    '):rep(nested - 1) .. '}'

        local joined = table.concat(res, '\n')
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
                if parsed_child == nil then
                    parsed_child = {}
                    parsed[key] = parsed_child
                end

                amend(parsed_child, value)

            elseif parsed_child == nil then
                parsed[key] = value
            end
        end
    end

    parse = function(path, defaults, global)
        local file = get_file(path, global)
        local options
        if file:exists() then
            options = loadfile(file.path)()
        else
            file:write('return ' .. format_table(defaults))
            options = {}
        end

        amend(options, defaults)

        return options
    end
end

settings.load = function(defaults, path, global)
    if type(path) == 'boolean' then
        path, global = global, path
    end

    path = path or 'settings.lua'
    global = global ~= nil and global

    local options = parse(path, defaults, global)

    info_cache[options] = {
        path = path,
        defaults = defaults,
        global = global,
    }

    settings.save(options)
    settings.settings_change:trigger(options)

    return options
end

local save_options = function(options, info)
    get_file(info.path, info.global):write('return ' .. format_table(options))
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
            current[key] = type(value) == 'table' and update(current[key], value) or value
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
                local parsed = parse(info.path, info.defaults)
                update(options, parsed)
                settings.save(options)
                settings.settings_change:trigger(options)
            end
        end
    end

    account.login:register(reparse)
    account.logout:register(reparse)
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
