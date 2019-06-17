local chat = require('chat')
local command = require('command')
local event = require('event')
local math = require('math')
local shared = require('shared')
local server = require('shared.server')
local string = require('string')
local structs = require('structs')
local table = require('table')

query_server = shared.new('query')

local query_result = {}

query_server.env = {}
query_server.env.query_response = function(path, setting)
    query_result.path = path
    query_result.setting = setting
end

local data = server.new(structs.struct({
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

local get = function(source, addon, path, options)
    data.get:trigger(addon, path, options)
    print_setting(source, query_result.path, query_result.setting)
end

local set = function(source, addon, path, value, options)
    data.set:trigger(addon, path, value, options)
    print_setting(source, query_result.path, query_result.setting)
end

settings_command:register_source('get', get, '<addon:string> <path:string> [options:string]')
settings_command:register_source('set', set, '<addon:string> <path:string> <value:string> [options:string]')
