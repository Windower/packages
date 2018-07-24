-- TODO: Consider adding a title row that describes each column to reduce clutter.
-- TODO: Consider adding distance to player as a column
-- TODO: Consider adding debuff image functionality.
-- TODO: Consider adding settings to show different data on player vs partymembers
-- TODO: Targetting needs more work, try and figure out how it will work with <stal>
-- TODO: Consider not displaying mp of jobs/subjob combinations that do not have mp, incorrectly shows as red

-- Known Issues:
-- TODO: Party members will briefly show as 'DEAD' when zoning into the same zone as the player.
-- TODO: When party members are invited or kicked, addon will temporarily freeze, probably because of how many 0x0DD packets go off at once.
-- TODO: Sometimes party members zone will be one zone behind, taking any action will fix it however.
-- TODO: Currently very slow to correctly update buff lists for the party, even just for the player.

local player = require('player')
local ui = require('ui')
local string = require('string')
local res = require('resources')
local status_effects = require('status_effects')
local packets = require('packets')
local chat = require('chat')
local command = require('command')
local settings = require('settings')
local target = require('target')
local party = require('party')
local math = require('math')
local os = require('os')
local enumerable = require('enumerable')

local debuffs = require('debuff_priority_list')
local status_list = {debuffs, res.buffs}

local hp_modes = {'missinghp', 'hp', 'hp/hp_max', 'hide'}
local mp_modes = {'mp', 'mp/mp_max', 'hide'}
local status_modes = {'debuffs', 'all statuses', 'no statuses'}

local defaults = {
    names_visible = true,
    hp_mode_index = 1,
    mp_mode_index = 3,
    status_mode_index = 3,
    tp_visible = false,
    dynamic_coloring = true,
    text_size = 20,
    text_typeface = 'Consolas',
    global_window_state = {
        style = 'chromeless',
        color = ui.color.black,
        closable = true,
        x = 20,
        y = 100,
        width = 500,
    }
}

local global_window_state = {}

settings.settings_change:register(function()
    for key, value in pairs(defaults.global_window_state) do
        global_window_state[key] = value
    end
end)

local options = settings.load(defaults)

local global_window_closed = false
local outer_padding = 2
local left_inner_padding = 2
local upper_inner_padding = 2
local lower_inner_padding = 5
local row_window_height = options.text_size + upper_inner_padding + lower_inner_padding
global_window_state.height = party.alliance.party_1_count * (row_window_height + outer_padding) + outer_padding

local get_name = function(pos)
    if options.names_visible then
        return string.format('%5.5s ', party[pos].name)
    else
        return ''
    end
end

local get_hp = function(pos)
    if hp_modes[options.hp_mode_index] == 'hide' then
        return ''
    elseif party[pos].hp == 0 and hp_modes[options.hp_mode_index] == 'missinghp' then
        return 'mHP:' .. string.format('%-5.5s ', 'DEAD')
    elseif party[pos].hp == 0 and hp_modes[options.hp_mode_index] == 'hp/hp_max' then
        return 'HP:' .. string.format('%-9.9s ', 'DEAD')
    elseif party[pos].hp == 0 then
        return 'HP:' .. string.format('%4.4s ', 'DEAD')
    elseif hp_modes[options.hp_mode_index] == 'missinghp' then
        return 'mHP:-' .. string.format('%-4.4s ', math.floor(party[pos].hp * 100 / party[pos].hp_percent) - party[pos].hp)
    elseif hp_modes[options.hp_mode_index] == 'hp/hp_max' then
        return 'HP:' .. string.format('%4.4s', party[pos].hp) .. '/' .. string.format('%-4.4s ', math.floor(party[pos].hp * 100 / party[pos].hp_percent))
    else
        return 'HP:' .. string.format('%4.4s ', party[pos].hp)
    end
end

local color_ranges = enumerable.wrap({
    {percent = 10, color = 'darkred'},
    {percent = 24, color = 'red'},
    {percent = 49, color = 'darkorange'},
    {percent = 74, color = 'yellow'},
    {percent = 94, color = 'limegreen'},
    {percent = 100, color = 'darkgreen'},
})

local get_hp_mp_color = function(pos, hp_or_mp_percent)
    if not options.dynamic_coloring then
        return 'white'
    end

    return color_ranges:first(function(t)
        return hp_or_mp_percent <= t.percent
    end).color
end

local get_mp = function(pos)
    if mp_modes[options.mp_mode_index] == 'mp' then
        return string.format('MP:%4.4s ', party[pos].mp)
    elseif mp_modes[options.mp_mode_index] == 'mp/mp_max' then
        return string.format('MP:%4.4s', party[pos].mp) .. '/' .. string.format('%-4.4s ', math.floor(party[pos].mp * 100 / party[pos].mp_percent))
    else
        return ''
    end
end

local get_tp = function(pos)
    if options.tp_visible then
        return string.format('TP:%4.4s ', party[pos].tp)
    else
        return ''
    end
end

local get_tp_color = function(pos)
    if party[pos].tp < 1000 or not options.dynamic_coloring then
        return 'white'
    else
        return 'dodgerblue'
    end
end

local get_status_string = function(pos)
    if status_modes[options.status_mode_index] ~= 'no statuses' then
        local statuses = ''
        local status_count = 0
        if pos == 1 then
            for _, status in pairs(status_list[options.status_mode_index]) do
                if status_effects.player[status.id][1] then
                    status_count = status_count + 1
                    if status_count ~= 1 then
                        statuses = statuses .. ' ' .. status.en
                    else
                        statuses = statuses .. status.en
                    end
                end
            end
        else
            status_count = 0
            for _, status in pairs(status_list[options.status_mode_index]) do
                if status_effects.party[pos - 1][status.id][1] then
                    status_count = status_count + 1
                    if status_count ~= 1 then
                        statuses = statuses .. ' ' .. status.en
                    else
                        statuses = statuses .. status.en
                    end
                end
            end
        end
        statuses = statuses:gsub('STRDown DEXDown VITDown AGIDown INTDown MNDDown CHRDown', 'Impact')
        return statuses
    else
        return ''
    end
end

local party_display_strings = {{}, {}, {}, {}, {}, {}}

local update_party_name_hp_mp_tp_strings = function(update_type, zone_check, party_pos)
    local start = nil
    local end_point = nil
    if party_pos and party_pos ~= 0 then
        start, end_point = party_pos, party_pos
    elseif party_pos and party_pos == 0 then
        -- Do nothing
    elseif update_type == 'player_only' then
        start, end_point = 1, 1
    elseif update_type == 'party_only' then
        start, end_point = 2, 6
    elseif update_type == 'both' then
        start, end_point = 1, 6
    end

    if start and end_point then
        for i = start, end_point do
            if party[i] and party[i].zone_id == party[1].zone_id and not zone_check then
                local name_job_hp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_hp_mp_color(i, party[i].hp_percent)
                local name_job_hp = get_name(i) .. get_hp(i)
                local name_job_hp_format = string.format('[' .. name_job_hp .. ']{' .. name_job_hp_format_string .. '}')

                local mp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_hp_mp_color(i, party[i].mp_percent)
                local mp_format = string.format('[' .. get_mp(i) .. ']{' .. mp_format_string .. '}')

                local tp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_tp_color(i)
                local tp_format = string.format('[' .. get_tp(i) .. ']{' .. tp_format_string .. '}')

                party_display_strings[i].name_hp_mp_tp = name_job_hp_format .. mp_format .. tp_format
            elseif party[i] and party[i].zone_id ~= party[1].zone_id then
                local name_zone_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold white'
                local name_zone = get_name(i) .. res.zones[party[i].zone_id].en
                local name_zone_format = string.format('[' .. name_zone .. ']{' .. name_zone_format_string .. '}')

                party_display_strings[i].name_hp_mp_tp = name_zone_format
            elseif party[i] and party[i].zone_id == party[1].zone_id and zone_check then
                -- Do not change strings
            else
                party_display_strings[i].name_hp_mp_tp = ''
            end
        end
    end
end
update_party_name_hp_mp_tp_strings('both')

local update_party_status_strings = function(update_type, zone_check)
    local start = 1
    local end_point = 1
    if update_type == 'player_only' then
        start, end_point = 1, 1
    elseif update_type == 'party_only' then
        start, end_point = 2, 6
    elseif update_type == 'both' then
        start, end_point = 1, 6
    end

    for i = start, end_point do
        if party[i] and party[i].zone_id == party[1].zone_id and not zone_check then
            local debuffs_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold white'
            local debuffs_format = string.format('[' .. get_status_string(i) .. ']{' .. debuffs_format_string .. '}')
            party_display_strings[i].debuffs = debuffs_format
        elseif party[i] and zone_check and party[i].zone_id == party[1].zone_id then
            -- Don't want to change debuffs here
        else
            party_display_strings[i].debuffs = ''
        end
    end
end
update_party_status_strings('both')

local party_window_states = {}

local create_party_window_states = function()
    for i = 1, 6 do
        party_window_states[i] = {
            style = 'chromeless',
            x = options.global_window_state.x + outer_padding,
            width = options.global_window_state.width - 2 * outer_padding,
            height = row_window_height,
            y = options.global_window_state.y + i * outer_padding + (i - 1) * row_window_height,
        }
    end
end
create_party_window_states()

local update_ui_dimensions = function()
    row_window_height = options.text_size + upper_inner_padding + lower_inner_padding
    global_window_state.y = options.global_window_state.y - (party.alliance.party_1_count - 1) * (row_window_height + outer_padding)
    global_window_state.x = options.global_window_state.x
    global_window_state.width = options.global_window_state.width
    global_window_state.height = party.alliance.party_1_count * (row_window_height + outer_padding) + outer_padding
    for i, row_window in ipairs(party_window_states) do
        row_window.x = options.global_window_state.x + outer_padding
        row_window.width = options.global_window_state.width - 2 * outer_padding
        row_window.y = global_window_state.y + outer_padding * i + row_window_height * (i - 1)
        row_window.height = row_window_height
    end
end

local check_target_for_row_highlighting = function()
    local entity = target.t or target.st
    for i = 1, 6 do
        if entity and party[i] then
            if entity.name == party[i].name then
                party_window_states[i].color = ui.color.rgb(30, 30, 30)
            else
                party_window_states[i].color = ui.color.black
            end
        else
            party_window_states[i].color = ui.color.black
        end
    end
end

local get_party_member_position = function(member_id)
    for pos = 1, 6 do
        if party[pos].id == member_id then
            return pos
        end
    end
    return 0
end

local zoning = false

-- Player zone out packet
packets.incoming[0x00B]:register(function()
    zoning = true
end)

-- 0x0DF appears to change when party members (including the player) hp/mp/tp changes
packets.incoming[0x0DF]:register(function(p)
    update_party_name_hp_mp_tp_strings('both', false, get_party_member_position(p.id))
end)

-- This seems to change when buffs on self change
packets.incoming[0x063][0x09]:register(function()
    -- update_party_status_strings('player_only')
end)

-- Party member updates, joining/leaving party etc
packets.incoming[0x0C8]:register(function()
    zoning = false
    update_party_name_hp_mp_tp_strings('both')
    update_party_status_strings('both')
end)

-- Party buffs update packet
packets.incoming[0x076]:register(function()
    -- update_party_status_strings('party_only')
end)

ui.display(function()
    if not global_window_closed and not zoning then
        update_ui_dimensions()
        check_target_for_row_highlighting()
        global_window_state, global_window_closed = ui.window('global_window', global_window_state, function()
            for i = 1, 6 do
                if party[i] then
                    party_window_states[i] = ui.window('party_member_row', party_window_states[i], function()
                        ui.location(left_inner_padding, upper_inner_padding)
                        ui.text(party_display_strings[i].name_hp_mp_tp .. party_display_strings[i].debuffs)
                    end)
                else
                    break
                end
            end
        end)
    end
end)

local pm = command.new('pm')

local toggle_ui = function()
    global_window_closed = not global_window_closed
end

pm:register('t', toggle_ui)
pm:register('tog', toggle_ui)
pm:register('toggle', toggle_ui)

local toggle_name_display = function()
    options.names_visible = not options.names_visible
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('name', toggle_name_display)
pm:register('names', toggle_name_display)

local toggle_hp_display = function()
    options.hp_mode_index = (options.hp_mode_index % #hp_modes) + 1
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('hp', toggle_hp_display)

local toggle_mp_display = function()
    options.mp_mode_index = (options.mp_mode_index % #mp_modes) + 1
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('mp', toggle_mp_display)

local toggle_tp_display = function()
    options.tp_visible = not options.tp_visible
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('tp', toggle_tp_display)

local toggle_status_display = function()
    options.status_mode_index = (options.status_mode_index % #status_modes) + 1
    settings.save(options)
    command.input('/echo Now displaying ' .. status_modes[options.status_mode_index])
    update_party_status_strings('both')
end

pm:register('st', toggle_status_display)
pm:register('status', toggle_status_display)

local toggle_dynamic_coloring = function()
    options.dynamic_coloring = not options.dynamic_coloring
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
    if options.dynamic_coloring then
        command.input('/echo Coloring ON')
    else
        command.input('/echo Coloring OFF')
    end
end

pm:register('color', toggle_dynamic_coloring)

local change_text_size = function(size)
    options.text_size = size
    settings.save(options)
    update_party_name_hp_mp_tp_strings('both')
    update_party_status_strings('both')
    update_ui_dimensions()
end

-- Not sure what to put for maximum allowable values here
pm:register('size', change_text_size, '[size:integer(0,50)=20]')

local change_position = function(x, y)
    options.global_window_state.x = x
    options.global_window_state.y = y
    settings.save(options)
    update_ui_dimensions()
end
-- Not sure what to put for maximum allowable values here
pm:register('pos', change_position, '[x:integer(0,50000)=20]', '[y:integer(0,50000)=100]')
pm:register('position', change_position, '[x:integer(0,50000)=20]', '[y:integer(0,50000)=100]')

local change_width = function(width)
    options.global_window_state.width = width
    settings.save(options)
    update_ui_dimensions()
end

pm:register('wid', change_width, '[width:integer(0,50000)=500]')
pm:register('width', change_width, '[width:integer(0,50000)=500]')

--[[
Copyright © 2018, BurntWaffle
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the BurntWaffle nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE BurntWaffle BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
