local string = require('string')
local ui = require('core.ui')
local player = require('player')
local target = require('target')
local math = require('math')

local player_frame_ui = function(helpers, options, state)
    local bar_width = state.width / 3
    local x_offset = 0
    for _, bar_settings in ipairs(options.bars) do

        local value_p, value
        if bar_settings.type == 'hp' then
            value_p = player.hp_percent / 100
            value = player.hp
        elseif bar_settings.type == 'mp' then
            value_p = player.mp_percent / 100
            value = player.mp
        else
            value_p = player.tp / 1000
            value = player.tp
        end

        ui.location(x_offset, 0)
        ui.size(bar_width - 12, 10)
        if bar_settings.type == 'tp' and value_p > 1 then
            -- special handling for TP because it can overfill the bar.

            -- base bar, previous color + slight dim from top bar's unfilled section
            ui.progress(1, { color = helpers.to_color(helpers.color_from_value(value_p-1, bar_settings.colors)) })

            -- top bar, we want this to be a higher color, and fill the expected amount. 1000, 2000 and 3000 = 100%, values in between should be a percent.
            local mod_p = 0
            if value_p > 0 then
                mod_p = value_p % 1 == 0 and 1 or value_p % 1 
            end

            ui.location(x_offset, 0)
            ui.size(bar_width - 12, 10)
            ui.progress(mod_p, { color = helpers.to_color(helpers.color_from_value(value_p, bar_settings.colors)) })            
        else
            ui.progress(value_p, { color = helpers.to_color(helpers.color_from_value(value_p, bar_settings.colors)) })
        end

        ui.location(x_offset + 6, 2)
        if bar_settings.show_percent then
            ui.text(string.format('[%s  %s]{%s}[: %s%%]{%s}',bar_settings.type:upper(), value, bar_settings.value_font, value_p * 100, bar_settings.percent_font))
        else
            ui.text(string.format('[%s  %s]{%s}',bar_settings.type:upper(), value, bar_settings.value_font))
        end

        x_offset = x_offset + bar_width
    end
end

local target_frame_ui = function(targ, target_type, helpers, options, state)
    if targ or state.style == 'layout' then
        ui.location(0, 0)
        ui.size(state.width, 10)

        local value_p = targ and targ.hp_percent / 100 or 0.73

        ui.progress(value_p, { color = helpers.to_color(helpers.color_from_value(value_p, options.colors)) })

        local t_name = targ and targ.name or target_type..' Name'
        ui.location(6, 1)
        ui.text(string.format('[%s]{%s}[: %s%%]{%s}', t_name, options.name_font, value_p * 100, options.percent_font))
    end
end

local options_state = {
    selection = nil,
}
local options_frame_ui = function(helpers, options, window_state)
    -- frame selection
    ui.location(0, 0)
    options_state.selection = ui.radio('player', 'Player', options_state.selection == 'player') and 'player' or nil
    ui.location(50, 0)
    options_state.selection = ui.radio('target', 'Target', options_state.selection == 'target') and 'target' or nil
    ui.location(100, 0)
    options_state.selection = ui.radio('subtarget', 'Subtarget', options_state.selection == 'subtarget') and 'subtarget' or nil
    ui.location(170, 0)
    options_state.selection = ui.radio('focustarget', 'Focustarget', options_state.selection == 'focustarget') and 'focustarget' or nil

    -- display options
    ui.location(0, 30)
    ui.text(options_state.selection or 'Unselected')

end

local position_options_ui = function(helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    ui.text('Position:  x: ')
    ui.location(x_offset + 65, y_offset)
    ui.size(60, 20)
    options.x = tonumber(ui.edit('pos_x', tostring(options.x)))

    ui.location(x_offset + 130, y_offset)
    ui.text('y: ')
    ui.location(x_offset + 150, y_offset)
    ui.size(60, 20)
    options.y = tonumber(ui.edit('pos_y', tostring(options.y)))

    return options, x_offset, y_offset + 24
end

local player_options_ui = function(helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    if ui.check('hide', 'Hide', options.hide) then
        options.hide = not options.hide
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Width: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.width = tonumber(ui.edit('width', tostring(options.width)))
    y_offset = y_offset + 24

    options.pos, x_offset, y_offset = position_options_ui(helpers, options.pos, x_offset, y_offset)
    return options, x_offset, y_offset
end

local target_options_ui = function(helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    if ui.check('hide', 'Hide', options.hide) then
        options.hide = not options.hide
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Width: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.width = tonumber(ui.edit('width', tostring(options.width)))
    y_offset = y_offset + 24

    options.pos, x_offset, y_offset = position_options_ui(helpers, options.pos, x_offset, y_offset)
    return options, x_offset, y_offset
end

return {
    player = player_frame_ui,
    target = function(h, o, s) return target_frame_ui(target.t, 'Target', h, o, s) end,
    subtarget = function(h, o, s) return target_frame_ui(target.st, 'Subtarget', h, o, s) end,
    focustarget = function(h, o, s) return target_frame_ui(target.focusst, 'Focustarget', h, o, s) end,
    options = options_frame_ui,
    player_options = player_options_ui,
    target_options = target_options_ui,
    subtarget_options = target_options_ui,
    focustarget_options = target_options_ui,
}