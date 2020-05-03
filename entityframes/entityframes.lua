local ui = require('core.ui')
local command = require('core.command')
local string = require('string')
local math = require('math')

local settings = require('settings')

local helpers = require('helpers')
local frame_ui = require('frame_ui')
local actions = require('action_handling')

local options = require('options')

local state = {
    layout = false,
}

local frame_height = 35

local frames = {
    player = {
        title = 'Player',
        style = 'normal',
        width = options.frames.player.width,
        min_height = frame_height,
        max_height = frame_height,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    target = {
        title = 'Target',
        style = 'normal',
        width = options.frames.target.width,
        min_height = frame_height,
        max_height = frame_height,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    subtarget = {
        title = 'Sub Target',
        style = 'normal',
        width = options.frames.subtarget.width,
        min_height = frame_height,
        max_height = frame_height,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    focustarget = {
        title = 'Focus Target',
        style = 'normal',
        width = options.frames.focustarget.width,
        min_height = frame_height,
        max_height = frame_height,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    },
    aggro = {
        title = 'Aggro Mobs',
        style = 'normal',
        width = options.frames.aggro.width,
        min_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12,
        max_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12,
        resizable = true,
        moveable = true,
        closeable = false,
        color = ui.color.rgb(0,0,0,0),
    }
}
local options_window = {
    title = 'Entity Frame Options',
    style = 'normal',
    width = 400,
    height = 200,
    resizable = false,
    moveable = true,
    closable = true, 
    selection = 'player',
}

for name, frame in pairs(frames) do
    helpers.init_frame_position(frame, options.frames[name])
end
helpers.init_frame_position(options_window, { pos = { x = -50, y = -200, x_anchor = 'center', y_anchor = 'center' } } )

ui.display(function()
    for name, frame in pairs(frames) do
        if state.layout then
            frame.style = 'layout'
        else
            frame.style = 'chromeless'
        end
    end

    for name, frame in pairs(frames) do
        if options.frames[name].show then
            frames[name] = ui.window(name, frames[name], function()
                frame_ui[name].draw_window(helpers, options.frames[name], frame)
            end)

            frame_ui[name].draw_decoration(helpers, options.frames[name], frames[name])
        end
    end

    if state.layout then
        local temp_options, options_closed = ui.window('options', options_window, function()
            options, options_window.width, options_window.height = frame_ui.options(helpers, frames, options, options_window)
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