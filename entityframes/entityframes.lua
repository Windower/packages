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

local defaults = {
    frames = {
        player = {
            pos = { x = 0.35, y = -290},
            width = 500,
            hide = false,
            bars = {
                { type = 'hp', color = { r = 136, g = 179, b = 022, a = 255}, show_percent = true,  value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', },
                { type = 'mp', color = { r = 184, g = 084, b = 121, a = 255}, show_percent = true,  value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', },
                { type = 'tp', color = { r = 251, g = 176, b = 000, a = 255}, show_percent = false, value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', },
            },
        },
    },
}

local options = settings.load(defaults)

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
    }
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

    if not options.frames.player.hide or state.layout then
        frames.player, options.frames.player.hide = ui.window('player', frames.player, function()
            frame_ui.player(helpers, options, frames.player)
        end)
    end
end)

local ef = command.new('ef')
ef:register('layout', function()
    state.layout = not state.layout

    if not state.layout then
        -- save_frames()
    end
end)