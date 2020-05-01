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

return {
    player = player_frame_ui,
    target = function(h, o, s) return target_frame_ui(target.t, 'Target', h, o, s) end,
    subtarget = function(h, o, s) return target_frame_ui(target.st, 'Subtarget', h, o, s) end,
    focustarget = function(h, o, s) return target_frame_ui(target.focusst, 'Focustarget', h, o, s) end,
}