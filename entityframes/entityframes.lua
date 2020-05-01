local ui = require('core.ui')
local command = require('core.command')
local string = require('string')
local table = require('table')

local party = require('party')
local player = require('player')
local target = require('target')
local packets = require('packets')
local entities = require('entities')
local settings = require('settings')

local helpers = require('helpers')
local frame_ui = require('frame_ui')

local options = require('options')

local state = {
    layout = false,
}

local frames = {
    player = {
        title = 'Player',
        style = 'normal',
        width = options.frames.player.width,
        min_height = 30,
        max_height = 30,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    target = {
        title = 'Target',
        style = 'normal',
        width = options.frames.target.width,
        min_height = 30,
        max_height = 30,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    subtarget = {
        title = 'Subtarget',
        style = 'normal',
        width = options.frames.subtarget.width,
        min_height = 30,
        max_height = 30,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    focustarget = {
        title = 'Focus Target',
        style = 'normal',
        width = options.frames.focustarget.width,
        min_height = 30,
        max_height = 30,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
}

helpers.init_frame_positions(frames, options)

ui.display(function()
    for name, frame in pairs(frames) do
        if state.layout then
            frame.style = 'layout'
        else
            frame.style = 'chromeless'
        end
    end

    for name, frame in pairs(frames) do
        if not options.frames[name].hide or state.layout then
            frames[name], options.frames[name].hide = ui.window(name, frames[name], function()
                frame_ui[name](helpers, options.frames[name], frame)
            end)
        end
    end
end)

local ef = command.new('ef')
ef:register('layout', function()
    state.layout = not state.layout

    if not state.layout then
        -- save_frames()
    end
end)