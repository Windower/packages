local string = require('string')
local ui = require('core.ui')
local player = require('player')
local party = require('party')
local target = require('target')
local windower = require('windower')
local math = require('math')
local os = require('os')

require('action_handling')

local get_cycle = function(cycles, start)
    local now = os.clock()
    local t = start
    local i = 1
    local s = false
    while t < now do
        t = t + cycles[i]
        i = i + 1
        if i > #cycles then
            i = i % (#cycles)
        end
        s = not s
    end
    return s
end

local short_letters = 'liI1 -\'".,'
local wide_letters = 'wWmM'
-- TODO: nuke this from orbit when the new UI stuff comes out
local calculate_text_size_terribly = function(s, font)
    local pt = tonumber(string.sub(string.match(font, ' (%d+)pt'), 0, -1)) / 12.0
    local n_short, n_wide, n = 0, 0, 0
    for i = 1, #s do
        local c = string.sub(s, i, i)
        if short_letters:contains(c) then
            n_short = n_short + 1
        elseif wide_letters:contains(c) then
            n_wide = n_wide + 1
        else
            n = n + 1
        end
    end
    return (n * 8 + n_short * 6 + n_wide * 11) * pt, pt * 14
end

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

local get_party_member = function(entity)
    for i = 1, 18 do
        local member = party[i]
        if member ~= nil and member.id == entity.id then
            return member
        end
    end
end

local entity_frame_ui = function(entity, target_type, helpers, options, state)
    local in_layout = state.style == 'layout'
    local party_member
    if entity then
        party_member = get_party_member(entity)
    end
    if (entity and (not entity.flags.hidden or party_member)) or in_layout then
        local x_offset = 0

        local dist_str_width, dist_str_height = calculate_text_size_terribly('00.0\'', options.distance_font)
        ui.location(x_offset, 15 - dist_str_height / 2)
        local dist = in_layout and 15.72 or math.sqrt(entity.distance)
        local dist_str = string.format('%0.1f', dist)
        if dist > 0 and (not options.hide_distance or in_layout) then
            ui.text(string.format('[%s\']{%s}', dist_str, options.distance_font))
        end

        x_offset = x_offset + dist_str_width + 4
        local is_targeted = entity and target.t and target.t.id == entity.id
        ui.location(x_offset, 13)
        if not options.hide_targeted and (in_layout or is_targeted) then
            ui.size(12, 12)
            ui.image(windower.package_path..'\\target.png', { color = helpers.to_color(options.target_color), })
        end

        x_offset = x_offset + 16
        ui.location(x_offset, 14)
        local value_p = in_layout and 0.73 or (party_member and party_member.hp_percent / 100 or entity.hp_percent / 100)
        ui.size(state.width - x_offset, 10)
        ui.progress(value_p, { color = helpers.to_color(helpers.color_from_value(value_p, options.colors)) })

        if party_member and not options.hide_party_resources then
            ui.location(state.width * 2 / 3 - 2, 23 - (options.party_resources_height / 2))
            ui.size(state.width / 6, options.party_resources_height)
            ui.progress(party_member.mp_percent / 100, { color = helpers.to_color(options.mp_color)})

            ui.location(state.width * 5 / 6,  23 - (options.party_resources_height / 2))
            ui.size(state.width / 6, options.party_resources_height)
            ui.progress(party_member.tp / 1000, { color = helpers.to_color(options.tp_color)})
        end

        x_offset = x_offset + 6
        local t_name = in_layout and target_type..' Name' or entity.name
        ui.location(x_offset , 14)
        if party_member then
            ui.text(string.format('[%s  %i]{%s}[: %s%%]{%s}', t_name, party_member.hp, options.name_font, party_member.hp_percent, options.percent_font))
        else
            ui.text(string.format('[%s]{%s}[: %s%%]{%s}', t_name, options.name_font, value_p * 100, options.percent_font))
        end

        if not options.hide_action then
            if in_layout or current_actions[entity.id] then
                local action = in_layout and 'Casting Action' or current_actions[entity.id].action.en
                local width, height = calculate_text_size_terribly(action, options.action_font)
                ui.location(state.width - width - 20, 14 - height)
                ui.text(string.format('[%s]{%s}', action, options.action_font))
            elseif previous_actions[entity.id] and os.clock() < previous_actions[entity.id].time + options.complete_action_hold_time then
                local action = previous_actions[entity.id]
                if not action.interrupted or get_cycle(options.flash_cycle, action.time) then
                    local font = action.interrupted and options.interrupted_action_font or options.complete_action_font
                    local width, height = calculate_text_size_terribly(action.action.en, font)
                    ui.location(state.width - width - 20, 14 - height)
                    ui.text(string.format('[%s]{%s}', action.action.en, font))
                end
            end
        end
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
    target = function(h, o, s, a) return entity_frame_ui(target.t, 'Target', h, o, s, a) end,
    subtarget = function(h, o, s, a) return entity_frame_ui(target.st, 'Subtarget', h, o, s, a) end,
    focustarget = function(h, o, s, a) return entity_frame_ui(target.focusst, 'Focustarget', h, o, s, a) end,
    options = options_frame_ui,
    player_options = player_options_ui,
    target_options = target_options_ui,
    subtarget_options = target_options_ui,
    focustarget_options = target_options_ui,
}