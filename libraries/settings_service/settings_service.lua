local chat = require('core.chat')
local command = require('core.command')
local event = require('core.event')
local math = require('math')
local channel = require('core.channel')
local server = require('shared.server')
local string = require('string')
local struct = require('struct')
local table = require('table')

query_server = channel.new('query')

local query_result = {}

query_server.env = {}
query_server.env.query_response = function(path, setting)
    query_result.path = path
    query_result.setting = setting
end

local data = server.new(struct.struct({
    get                 = {data = event.new()},
    set                 = {data = event.new()},
}))

local math_max = math.max
local string_rep = string.rep
local table_sort = table.sort

local flatten
flatten = function(t, prefix)
    local values = {}
    local count = 0

    for key, value in pairs(t) do
        if type(value) == 'table' then
            local flattened = flatten(value, prefix .. '.' .. key)

            for i = 1, #flattened do
                local flattened_value = flattened[i]
                count = count + 1
                values[count] = {path = flattened_value.path, setting = flattened_value.setting}
            end
        else
            count = count + 1
            values[count] = {path = prefix .. '.' .. key, setting = value}
        end
    end

    return values
end

local print_setting = function(source, path, setting)
    local values = type(setting) == 'table' and flatten(setting, path) or {{path = path, setting = setting}}

    table_sort(values, function(v1, v2)
        return v1.path < v2.path
    end)

    if source == 'console' then
        local max_length = 0
        for i = 1, #values do
            max_length = math_max(max_length, #values[i].path)
        end

        print('Settings:')
        for i = 1, #values do
            local value = values[i]
            print('    ' .. value.path .. string_rep(' ', max_length - #value.path + 2) .. tostring(value.setting))
        end
    else
        chat.add_text('Settings:')
        for i = 1, #values do
            local value = values[i]
            chat.add_text('> ' .. value.path .. ': ' .. tostring(value.setting))
        end
    end
end

local settings_command = command.new('settings')

local get = function(source, addon, path, id)
    data.get:trigger(addon, path, id)
    print_setting(source, query_result.path, query_result.setting)
end

local set = function(source, addon, path, value, id)
    data.set:trigger(addon, path, value, id)
    print_setting(source, query_result.path, query_result.setting)
end

settings_command:register_source('get', get, '<addon:string> <path:string> [id:string]')
settings_command:register_source('set', set, '<addon:string> <path:string> <value:string> [id:string]')

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
