local account = require('account')
local files = require('files')
local windower = require('windower')
local event = require('event')
require('table')
require('string')
require('os')

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
