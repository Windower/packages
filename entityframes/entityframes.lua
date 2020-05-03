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
    width = 10,
    height = 10,
    resizable = false,
    moveable = true,
    closeable = true, 
}
local options_font = 'Roboto 10pt color:white'

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
        if not options.frames[name].hide then
            frames[name] = ui.window(name, frames[name], function()
                frame_ui[name].draw_window(helpers, options.frames[name], frame)
            end)

            frame_ui[name].draw_decoration(helpers, options.frames[name], frames[name])
        end
    end

    if state.layout then
        local temp_options, options_closed = ui.window('options', options_window, function()
            -- frame selection
            local y_offset = 4
            local x_offset = 4
            ui.location(x_offset, y_offset)
            for name, frame in pairs(frames) do
                if ui.radio(name, string.format('[%s]{%s}', frame.title, options_font), options_window.selection == name) then
                    options_window.selection = name
                end
                local name_width, name_height = helpers.calculate_text_size_terribly(frame.title, options_font)
                x_offset = x_offset + name_width + 20
                ui.location(x_offset, y_offset)
            end

            options_window.width = math.max(options_window.width, x_offset)
            x_offset = 4

            -- display options
            y_offset = y_offset + 40

            if options_window.selection then
                options.frames[options_window.selection], x_offset, y_offset = frame_ui[options_window.selection..'_options'](options_window.selection, helpers, options.frames[options_window.selection], x_offset, y_offset)
            end

            frames.aggro.min_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12
            frames.aggro.max_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12

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