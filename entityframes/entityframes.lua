local ui = require('core.ui')
local command = require('core.command')
local string = require('string')
local math = require('math')
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
        title = 'Sub Target',
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
local options_window = {
    title = 'Entity Frame Options',
    style = 'normal',
    width = 10,
    height = 10,
    resizable = false,
    moveable = true,
    closeable = false, 
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

    if state.layout then
        local temp_options, options_closed = ui.window('options', options_window, function()
            -- frame selection
            local y_offset = 4
            local x_offset = 4
            ui.location(x_offset, y_offset)
            for name, frame in pairs(frames) do
                if ui.radio(name, frame.title, options_window.selection == name) then
                    options_window.selection = name
                end
                x_offset = x_offset + (#name * 10)
                ui.location(x_offset, y_offset)
            end

            options_window.width = math.max(options_window.width, x_offset)
            x_offset = 4

            -- display options
            y_offset = y_offset + 40

            if options_window.selection then
                local frame_options = options.frames[options_window.selection]
                frame_options, x_offset, y_offset = frame_ui[options_window.selection..'_options'](helpers, frame_options, x_offset, y_offset)
                options.frames[options_window.selection] = frame_options
            end

            x_offset = 4
            ui.location(x_offset, y_offset)
            if ui.button('save', 'Save') then
                settings.save()
            end
            y_offset = y_offset + 30

            options_window.height = y_offset
        end)
        options_window.x = temp_options.x
        options_window.y = temp_options.y
    end
end)

local ef = command.new('ef')
ef:register('layout', function()
    state.layout = not state.layout

    if not state.layout then
        -- save_frames()
    end
end)