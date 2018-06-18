local settings = require('settings')
local ui = require('ui')
local os = require('os')
local table = require('table')
local string = require('string')

local defaults = {
    x = 0,
    y = 0,
}

local options = settings.load(defaults)

local times = {}

ui.display(function()
    if #times >= 10 then
        table.remove(times, 1)
    end
    times[#times + 1] = os.clock()

    ui.location(options.x, options.y)

    ui.text(string.format('%.1f', (#times - 1) / (times[#times] - times[1])))
end)
