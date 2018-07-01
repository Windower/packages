local account = require('account')
local event = require('event')
local files = require('files')
local os = require('os')
local string = require('string')
local table = require('table')
local windower = require('windower')

local info_cache = {}

local settings = {}

local amend
amend = function(main, defaults)
    for key, value in pairs(defaults) do
        if main[key] == nil then
            if type(value) == 'table' then
                local new = {}
                amend(new, value)
                main[key] = new
            else
                main[key] = value
            end
        else
            assert((type(value) == 'table') == (type(main[key]) == 'table'), 'Incompatible settings for key ' .. key .. '! Defaults specify a ' .. type(value) .. ', the file has a ' .. type(main[key]) .. '.')

            if type(value) == 'table' then
                amend(main[key], value)
            end
        end
    end
end

local get_file = function(path)
    local dir = windower.settings_path .. '\\' .. account.name .. '_' .. (account.server_name or account.id) .. '\\'
    os.execute('mkdir "' .. dir .. '" >nul 2>nul')
    return files.create(dir .. path)
end

local format_value = function(value)
    if type(value) == 'string' then
        return '\'' .. value .. '\''
    else
        return tostring(value)
    end
end

local format_table
format_table = function(t, nested)
    nested = nested or 1

    local res = {}
    res[1] = '{'

    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local indent = ('    '):rep(nested)

    for _, key in ipairs(keys) do
        local child = t[key]
        local formatted_key = type(key) == 'string' and key:match('^%a[%w_]+$') or '[' .. format_value(key) .. ']'
        res[#res + 1] = indent .. formatted_key .. ' = ' .. (type(child) == 'table' and format_table(child, nested + 1) or format_value(child)) .. ','
    end

    res[#res + 1] = ('    '):rep(nested - 1) .. '}'

    return table.concat(res, '\n')
end

settings.load = function(defaults, path)
    path = type(defaults) == 'string' and defaults or path or 'settings.lua'
    defaults = type(defaults) == 'table' and defaults or nil

    local file
    if account.logged_in then
        file = get_file(path)
    end

    local options
    if file == nil then
        options = {}
    elseif not file:exists() then
        file:write('return ' .. format_table(defaults))
        options = {}
    else
        options = loadfile(file.path)()
    end

    amend(options, defaults)

    info_cache[options] = {
        path = path,
        defaults = defaults,
    }

    return options
end

settings.save = function(options)
    if not account.logged_in then
        return
    end

    local info = info_cache[options]

    get_file(info.path):write('return ' .. format_table(options))
end

account.login:register(function()
    for options, info in pairs(info_cache) do
        for key in pairs(options) do
            options[key] = nil
        end

        local file = get_file(info.path)

        if not file:exists() then
            file:write('return ' .. format_table(options))
        else
            local file_options = loadfile(file.path)()
            amend(options, file_options)
        end

        amend(options, info.defaults)
    end

    for options, info in pairs(info_cache) do
        settings.settings_change:trigger(options)
    end
end)

account.logout:register(function()
    for options, info in pairs(info_cache) do
        for key in pairs(options) do
            options[key] = nil
        end

        amend(options, info.defaults)
    end

    for options, info in pairs(info_cache) do
        settings.settings_change:trigger(options)
    end
end)

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
