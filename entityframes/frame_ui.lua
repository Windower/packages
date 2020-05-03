local string = require('string')
local ui = require('core.ui')
local player = require('player')
local party = require('party')
local entities = require('entities')
local target = require('target')
local windower = require('windower')
local settings = require('settings')
local list = require('list')
local math = require('math')
local os = require('os')
local table = require('table')

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
        ui.size(bar_width - 8, 10)
        if bar_settings.type == 'tp' and value_p > 1 then
            -- special handling for TP because it can overfill the bar.

            -- base bar, previous color + slight dim from top bar's unfilled section
            ui.progress(1, { color = helpers.color_from_value(value_p-1, bar_settings.colors) })

            -- top bar, we want this to be a higher color, and fill the expected amount. 1000, 2000 and 3000 = 100%, values in between should be a percent.
            local mod_p = 0
            if value_p > 0 then
                mod_p = value_p % 1 == 0 and 1 or value_p % 1 
            end

            ui.location(x_offset, 0)
            ui.size(bar_width - 8, 10)
            ui.progress(mod_p, { color = helpers.color_from_value(value_p, bar_settings.colors) })            
        else
            ui.progress(value_p, { color = helpers.color_from_value(value_p, bar_settings.colors) })
        end

        ui.location(x_offset + 6, 2)
        if bar_settings.show_percent then
            ui.text(string.format('[%s  %s]{%s}[: %s%%]{%s}',bar_settings.type:upper(), value, bar_settings.value_font, value_p * 100, bar_settings.percent_font))
        else
            ui.text(string.format('[%s  %s]{%s}',bar_settings.type:upper(), value, bar_settings.value_font))
        end

        x_offset = x_offset + bar_width + 4
    end
end

local player_frame_decoration = function(...)
end

local get_party_member = function(entity)
    for i = 1, 18 do
        local member = party[i]
        if member ~= nil and member.id == entity.id then
            return member
        end
    end
end

local entity_frame_ui = function(entity, target_type, helpers, options, state, x_offset, y_offset)
    local in_layout = state.style == 'layout'
    local party_member
    if entity then
        party_member = get_party_member(entity)
    end
    if (entity and (not entity.flags.hidden or party_member)) or in_layout then
        ui.location(x_offset, y_offset + 14)
        local value_p = in_layout and 0.73 or (party_member and party_member.hp_percent / 100 or entity.hp_percent / 100)
        ui.size(state.width - x_offset, 10)
        ui.progress(value_p, { color = helpers.color_from_value(value_p, options.colors) })

        if options.show_party_resources and options.party_resources_height ~= nil then
            local mp = in_layout and 67 or (party_member and party_member.mp_percent or nil)
            local tp = in_layout and 700 or (party_member and party_member.tp or nil)

            if mp then
                ui.location(state.width * 2 / 3 - 12, y_offset + 23 - (options.party_resources_height / 2))
                ui.size(state.width / 6, options.party_resources_height)
                ui.progress(mp / 100, { color = options.mp_color})
            end

            if tp then
                ui.location(state.width * 5 / 6 - 10,  y_offset + 23 - (options.party_resources_height / 2))
                ui.size(state.width / 6, options.party_resources_height)
                ui.progress(tp / 1000, { color = options.tp_color})
            end
        end

        x_offset = x_offset + 6
        local t_name = in_layout and target_type..' Name' or entity.name
        ui.location(x_offset , y_offset + 14)
        if party_member then
            ui.text(string.format('[%s  %i]{%s}[: %s%%]{%s}', t_name, party_member.hp, options.name_font, party_member.hp_percent, options.percent_font))
        else
            ui.text(string.format('[%s]{%s}[: %s%%]{%s}', t_name, options.name_font, value_p * 100, options.percent_font))
        end

        if options.show_action then
            if in_layout or current_actions[entity.id] then
                local action = in_layout and 'Casting Action' or current_actions[entity.id].action.en
                local width, height = helpers.calculate_text_size_terribly(action, options.action_font)
                ui.location(state.width - width - 20, y_offset + 13 - height)
                ui.text(string.format('[%s]{%s}', action, options.action_font))
            elseif previous_actions[entity.id] and os.clock() < previous_actions[entity.id].time + options.complete_action_hold_time then
                local action = previous_actions[entity.id]
                if not action.interrupted or get_cycle(options.flash_cycle, action.time) then
                    local font = action.interrupted and options.interrupted_action_font or options.complete_action_font
                    local width, height = helpers.calculate_text_size_terribly(action.action.en, font)
                    ui.location(state.width - width - 20, y_offset + 13 - height)
                    ui.text(string.format('[%s]{%s}', action.action.en, font))
                end
            end
        end
    end
end

local entity_frame_decorations = function(entity, target_type, helpers, options, state, x_offset, y_offset)
    local in_layout = state.style == 'layout'
    local party_member
    if entity then
        party_member = get_party_member(entity)
    end
    if (entity and (not entity.flags.hidden or party_member)) or in_layout then

        -- left side ornaments
        x_offset = x_offset + state.x
        y_offset = y_offset + state.y + 13
        local dist_str_width, dist_str_height = helpers.calculate_text_size_terribly('00.0\'', options.distance_font)
        x_offset = x_offset - dist_str_width - 20
        ui.location(x_offset, y_offset + 2 - dist_str_height / 2)
        local dist = in_layout and 15.72 or math.sqrt(entity.distance)
        local dist_str = string.format('%0.1f', dist)
        if dist > 0 and options.show_distance then
            ui.text(string.format('[%s\']{%s}', dist_str, options.distance_font))
        end

        x_offset = x_offset + dist_str_width + 4
        local is_targeted = entity and target.t and target.t.id == entity.id
        if options.show_targeted and (in_layout or is_targeted) then
            ui.location(x_offset, y_offset)
            ui.size(12, 12)
            ui.image(windower.package_path..'\\target.png', { color = options.target_color, })
        end

        -- right side ornaments
        x_offset = state.x + state.width + 4
        if options.show_target_target then
            local target_name = nil
            local target_name_font = options.target_target_font
            if in_layout then
                target_name = target_type..'\'s target'
            elseif entity and current_actions[entity.id] and options.show_action then
                target_name = current_actions[entity.id].target and current_actions[entity.id].target.name or nil
            elseif entity and entity.target_index ~= 0 then
                local target_entity = entities[entity.target_index]
                target_name = target_entity and target_entity.name or nil
            elseif entity and previous_actions[entity.id] and options.show_action and os.clock() < previous_actions[entity.id].time + options.complete_action_hold_time then
                target_name = previous_actions[entity.id].target and previous_actions[entity.id].target.name or nil
                target_name_font = options.complete_action_font
            elseif entity and options.show_aggro and aggro[entity.id] and os.clock() < aggro[entity.id].last_action_time + options.aggro_degrade_time then
                target_name = aggro[entity.id].primary_target.name
            end

            if target_name ~= nil and target_name ~= '' then
                ui.location(x_offset, y_offset)
                ui.size(12, 12)
                ui.image(windower.package_path..'\\attention.png')

                x_offset = x_offset + 12 + 4
                text_width, text_height = helpers.calculate_text_size_terribly(target_name, target_name_font)
                ui.location(x_offset, y_offset - text_height / 2)
                ui.text(string.format('[%s]{%s}', target_name, target_name_font))
                x_offset = x_offset + text_width + 5
            end
        end
    end
end

local sort_fns = {
    ['low-high'] = function(a, b)
        return a.hp_percent < b.hp_percent
    end,
    ['high-low'] = function(a, b)
        return a.hp_percent > b.hp_percent
    end,
    ['near-far'] = function(a, b)
        return a.distance < b.distance
    end,
    ['far-near'] = function(a, b)
        return a.distance > b.distance
    end,
}
local aggro_cache = nil

local aggro_frame_ui = function(helpers, options, state)
    local in_layout = state.style == 'layout'
    local aggrod_entities = list()
    for id, a in pairs(aggro) do
        if a.actor.hp_percent > 0 then
            aggrod_entities:add(a.actor)
        end
    end

    local sort_fn = options.entity_order or 'low-high'
    table.sort(aggrod_entities, sort_fns[sort_fn])
    aggro_cache = aggrod_entities

    local x_offset = 0
    local y_offset = 0
    local count = (in_layout and options.entity_count or math.min(#aggrod_entities, options.entity_count))
    for i = 1, count do
        local entity = aggrod_entities[i]
        entity_frame_ui(entity, 'Aggro', helpers, options.entity_frame, state, x_offset, y_offset)

        y_offset = y_offset + options.entity_padding
    end
end

local aggro_frame_decoration = function (helpers, options, state)
    local in_layout = state.style == 'layout'
    local aggrod_entities = aggro_cache

    local x_offset = 0
    local y_offset = 0
    local count = (in_layout and options.entity_count or math.min(#aggrod_entities, options.entity_count))
    for i = 1, count do
        local entity = aggrod_entities[i]
        entity_frame_decorations(entity, 'Aggro', helpers, options.entity_frame, state, x_offset, y_offset)

        y_offset = y_offset + options.entity_padding
    end
end

local position_options_ui = function(id, helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    ui.text('Position:  x: ')
    ui.location(x_offset + 65, y_offset)
    ui.size(60, 20)
    options.x = tonumber(ui.edit(id..'pos_x', tostring(options.x)))

    ui.location(x_offset + 130, y_offset)
    ui.text('y: ')
    ui.location(x_offset + 150, y_offset)
    ui.size(60, 20)
    options.y = tonumber(ui.edit(id..'pos_y', tostring(options.y)))

    return options, x_offset, y_offset + 24
end

local player_options_ui = function(id, helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    if ui.check(id..'show_frame', 'Show', options.show) then
        options.show = options.show
    end

    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Width: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.width = tonumber(ui.edit(id..'width', tostring(options.width)))
    y_offset = y_offset + 24

    options.pos, x_offset, y_offset = position_options_ui(id, helpers, options.pos, x_offset, y_offset)
    return options, x_offset, y_offset
end

local target_options_ui = function(id, helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    if ui.check(id..'show_frame', 'Show', options.show) then
        options.show = not options.show
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_action', 'Show Action', options.show_action) then
        options.show_action = not options.show_action
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_targeted', 'Show Targeted', options.show_targeted) then
        options.show_targeted = not options.show_targeted
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_target_target', 'Show Target\'s Target', options.show_target_target) then
        options.show_target_target = not options.show_target_target
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_distance', 'Show Distance', options.show_distance) then
        options.show_distance = not options.show_distance
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_party_resources', 'Show Party MP/TP', options.show_party_resources) then
        options.show_party_resources = not options.show_party_resources
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_aggro', 'Detect Aggro (experimental)', options.show_aggro) then
        options.show_aggro = not options.show_aggro
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Width: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.width = tonumber(ui.edit(id..'width', tostring(options.width)))
    y_offset = y_offset + 24

    options.pos, x_offset, y_offset = position_options_ui(id, helpers, options.pos, x_offset, y_offset)
    return options, x_offset, y_offset
end

local aggro_options_ui = function(id, helpers, options, x_offset, y_offset)
    ui.location(x_offset, y_offset)
    if ui.check(id..'show_frame', 'Show', options.show) then
        options.show = not options.show
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_action', 'Show Action', options.entity_frame.show_action) then
        options.entity_frame.show_action = not options.entity_frame.show_action
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_targeted', 'Show Targeted', options.entity_frame.show_targeted) then
        options.entity_frame.show_targeted = not options.entity_frame.show_targeted
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_target_target', 'Show Target\'s Target', options.entity_frame.show_target_target) then
        options.entity_frame.show_target_target = not options.entity_frame.show_target_target
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_distance', 'Show Distance', options.entity_frame.show_distance) then
        options.entity_frame.show_distance = not options.entity_frame.show_distance
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    if ui.check(id..'show_aggro', 'Detect Aggro (experimental)', options.entity_frame.show_aggro) then
        options.entity_frame.show_aggro = not options.entity_frame.show_aggro
    end
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Entities: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.entity_count = tonumber(ui.edit(id..'entities', tostring(options.entity_count)))
    y_offset = y_offset + 24

    ui.location(x_offset, y_offset)
    ui.text('Width: ')
    ui.location(x_offset + 40, y_offset)
    ui.size(60, 20)
    options.width = tonumber(ui.edit(id..'width', tostring(options.width)))
    y_offset = y_offset + 24

    options.pos, x_offset, y_offset = position_options_ui(id, helpers, options.pos, x_offset, y_offset)
    return options, x_offset, y_offset
end

local frame_options = {
    player = player_options_ui,
    target = target_options_ui,
    subtarget = target_options_ui,
    focustarget = target_options_ui,
    aggro = aggro_options_ui,
}
local options_font = 'Roboto 10pt color:white'

local options_frame_ui = function(helpers, frames, options, window_state)
        -- frame selection
        local y_offset = 4
        local x_offset = 4
        ui.location(x_offset, y_offset)
        for name, frame in pairs(frames) do
            if ui.radio(name, string.format('[%s]{%s}', frame.title, options_font), window_state.selection == name) then
                window_state.selection = name
            end
            local name_width, name_height = helpers.calculate_text_size_terribly(frame.title, options_font)
            x_offset = x_offset + name_width + 20
            ui.location(x_offset, y_offset)
        end

        local title_offset = x_offset
        x_offset = 4

        -- display options
        y_offset = y_offset + 40

        if window_state.selection then
            options.frames[window_state.selection], x_offset, y_offset = frame_options[window_state.selection](window_state.selection, helpers, options.frames[window_state.selection], x_offset, y_offset)
        end

        frames.aggro.min_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12
        frames.aggro.max_height = options.frames.aggro.entity_padding * options.frames.aggro.entity_count + 12

        x_offset = 4
        ui.location(x_offset, y_offset)
        if ui.button('save', 'Save') then
            settings.save()
        end
        y_offset = y_offset + 30

        return options, math.max(title_offset, x_offset), y_offset
end

return {
    player = { 
        draw_window = player_frame_ui,
        draw_decoration = player_frame_decoration,
    },
    target = { 
        draw_window = function(h, o, s) return entity_frame_ui(target.t, 'Target', h, o, s, 0, 0) end,
        draw_decoration = function(h, o, s) return entity_frame_decorations(target.t, 'Target', h, o, s, 0, 0) end,
    },
    subtarget = {
        draw_window = function(h, o, s) return entity_frame_ui(target.st, 'Subtarget', h, o, s, 0, 0) end,
        draw_decoration = function(h, o, s) return entity_frame_decorations(target.st, 'Subtarget', h, o, s, 0, 0) end,
    },
    focustarget = { 
        draw_window = function(h, o, s) return entity_frame_ui(target.focusst, 'Focustarget', h, o, s, 0, 0) end,
        draw_decoration = function(h, o, s) return entity_frame_decorations(target.focusst, 'Focustarget', h, o, s, 0, 0) end,
    },
    aggro = {
        draw_window = aggro_frame_ui,
        draw_decoration = aggro_frame_decoration,
    },
    options = options_frame_ui,
}