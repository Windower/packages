-- TODO: Replace command.input('/echo') with chat.add_text() when possible
-- TODO: Consider adding a title row that describes each column to reduce clutter.
-- TODO: Consider adding distance to player as a column
-- TODO: Consider adding debuff image functionality.
-- TODO: Consider adding settings to show different data on player vs partymembers
-- TODO: Optimize/revisit incoming packet code, in particular look into getting party zone ids to update correctly when party members zone, for now just display 'Not in zone'

-- Known Issues:
-- TODO: Party member will briefly show as 'DEAD' when zoning into the same zone as the player.
-- TODO: HP updates can be a bit slow, particularly after a cure.

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

local debuff_ids = require('debuff_ids')

local hp_modes = {'missinghp', 'hp', 'hp/hp_max', 'hide'}
local mp_modes = {'mp', 'mp/mp_max', 'hide'}

local zoning = false
local zone_out_time = os.clock()
local zone_in_delay = 10

local defaults = {
    names_visible = true,
    hp_mode_index = 1,
    mp_mode_index = 3,
    tp_visible = false,
    debuffs_visible = true,
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
local options = settings.load(defaults)

local function get_party_size()
    for i = 1, 6 do
        if not party[i] then
            return (i - 1)
        end
    end
    return 6
end

local global_window_state = {}
local function quick_shallow_copy()
    for key, value in pairs(options.global_window_state) do
        global_window_state[key] = value
    end
end
quick_shallow_copy()

local global_window_closed = false
local outer_padding = 2
local left_inner_padding = 2
local upper_inner_padding = 2
local lower_inner_padding = 5
local row_window_height = options.text_size + upper_inner_padding + lower_inner_padding
global_window_state.height = get_party_size() * (row_window_height + outer_padding) + outer_padding

local function get_name(pos)
    if options.names_visible then
        return string.format('%5.5s ', party[pos].name)
    else
        return ''
    end
end

local function get_hp(pos)
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

local function get_hp_color(pos)
    local color
    if not options.dynamic_coloring then
        color = 'white'
    elseif party[pos].hp_percent >= 95 then
        color = 'darkgreen'
    elseif party[pos].hp_percent >= 75 then
        color = 'limegreen'
    elseif party[pos].hp_percent >= 50 then
        color = 'yellow'
    elseif party[pos].hp_percent >= 25 then
        color = 'darkorange'
    elseif party[pos].hp_percent >= 11 then
        color = 'red'
    elseif party[pos].hp_percent < 11 then
        color = 'darkred'
    end
    return color
end

local function get_mp_color(pos)
    local color
    if not options.dynamic_coloring then
        color = 'white'
    elseif party[pos].mp_percent >= 95 then
        color = 'darkgreen'
    elseif party[pos].mp_percent >= 75 then
        color = 'limegreen'
    elseif party[pos].mp_percent >= 50 then
        color = 'yellow'
    elseif party[pos].mp_percent >= 25 then
        color = 'darkorange'
    elseif party[pos].mp_percent >= 11 then
        color = 'red'
    elseif party[pos].mp_percent < 11 then
        color = 'darkred'
    end
    return color
end

local function get_mp(pos)
    if mp_modes[options.mp_mode_index] == 'mp' then
        return string.format('MP:%4.4s ', party[pos].mp)
    elseif mp_modes[options.mp_mode_index] == 'mp/mp_max' then
        return string.format('MP:%4.4s', party[pos].mp) .. '/' .. string.format('%-4.4s ', math.floor(party[pos].mp * 100 / party[pos].mp_percent))
    else
        return ''
    end
end

local function get_tp(pos)
    if options.tp_visible then
        return string.format('TP:%4.4s ', party[pos].tp)
    else
        return ''
    end
end

local function get_tp_color(pos)
    if party[pos].tp < 1000 or not options.dynamic_coloring then
        return 'white'
    else
        return 'dodgerblue'
    end
end

local function get_debuff_string(pos)
    if options.debuffs_visible then
        debuffs = 'DB:'
        local debuff_count = 0
        if pos == 1 then
            for _, debuff_id in ipairs(debuff_ids) do
                if status_effects.player[debuff_id][1] then
                    debuff_count = debuff_count + 1
                    if debuff_count ~= 1 then
                        debuffs = debuffs .. ' ' .. res.buffs[debuff_id].en
                    else
                        debuffs = debuffs .. res.buffs[debuff_id].en
                    end
                end
            end
        else
            debuff_count = 0
            for _, debuff_id in ipairs(debuff_ids) do
                if status_effects.party[pos - 1][debuff_id][1] then
                    debuff_count = debuff_count + 1
                    if debuff_count ~= 1 then
                        debuffs = debuffs .. ' ' .. res.buffs[debuff_id].en
                    else
                        debuffs = debuffs .. res.buffs[debuff_id].en
                    end
                end
            end
        end
        debuffs = debuffs:gsub('STRDown DEXDown VITDown AGIDown INTDown MNDDown CHRDown', 'Impact')
        return debuffs
    else
        return ''
    end
end

local party_display_strings = {{}, {}, {}, {}, {}, {}}

local function update_party_name_hp_mp_tp_strings(update_type)
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
        if party[i] and party[i].zone_id == party[1].zone_id then
            local name_job_hp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_hp_color(i)
            local name_job_hp = get_name(i) .. get_hp(i)
            local name_job_hp_format = string.format('[' .. name_job_hp .. ']{' .. name_job_hp_format_string .. '}')

            local mp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_mp_color(i)
            local mp_format = string.format('[' .. get_mp(i) .. ']{' .. mp_format_string .. '}')

            local tp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_tp_color(i)
            local tp_format = string.format('[' .. get_tp(i) .. ']{' .. tp_format_string .. '}')

            local debuffs_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. 'white'
            local debuffs_format = string.format('[' .. get_debuff_string(i) .. ']{' .. debuffs_format_string .. '}')

            party_display_strings[i].name_hp_mp_tp = name_job_hp_format .. mp_format .. tp_format
        elseif party[i] and party[i].zone_id ~= party[1].zone_id then
            local name_zone_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold white'
            local name_zone = get_name(i) .. 'Not in zone'
            local name_zone_format = string.format('[' .. name_zone .. ']{' .. name_zone_format_string .. '}')

            party_display_strings[i].name_hp_mp_tp = name_zone_format
        else
            party_display_strings[i].name_hp_mp_tp = ''
        end
    end
end
update_party_name_hp_mp_tp_strings('both')

local function update_party_debuff_strings(update_type)
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
        if party[i] and party[i].zone_id == party[1].zone_id then
            local debuffs_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold white'
            local debuffs_format = string.format('[' .. get_debuff_string(i) .. ']{' .. debuffs_format_string .. '}')
            party_display_strings[i].debuffs = debuffs_format
        else
            party_display_strings[i].debuffs = ''
        end
    end
end
update_party_debuff_strings('both')

local party_window_states = {}

local function create_party_window_states()
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

local function update_ui_dimensions()
    row_window_height = options.text_size + upper_inner_padding + lower_inner_padding
    global_window_state.y = options.global_window_state.y - (get_party_size() - 1) * (row_window_height + outer_padding)
    global_window_state.x = options.global_window_state.x
    global_window_state.width = options.global_window_state.width
    global_window_state.height = get_party_size() * (row_window_height + outer_padding) + outer_padding
    for i, row_window in ipairs(party_window_states) do
        row_window.x = options.global_window_state.x + outer_padding
        row_window.width = options.global_window_state.width - 2 * outer_padding
        row_window.y = global_window_state.y + outer_padding * i + row_window_height * (i - 1)
        row_window.height = row_window_height
    end
end

local function get_row_string()
    local name_job_hp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_hp_color()
    local name_job_hp = get_name() .. get_hp()
    local name_job_hp_format = string.format('[' .. name_job_hp .. ']{' .. name_job_hp_format_string .. '}')

    local mp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_mp_color()
    local mp_format = string.format('[' .. get_mp() .. ']{' .. mp_format_string .. '}')

    local tp_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. get_tp_color()
    local tp_format = string.format('[' .. get_tp() .. ']{' .. tp_format_string .. '}')

    local debuffs_format_string = options.text_typeface .. ' ' .. tostring(options.text_size) .. 'px bold ' .. 'white'
    local debuffs_format = string.format('[' .. party_data[1].debuffs .. ']{' .. debuffs_format_string .. '}')

    return name_job_hp_format .. mp_format .. tp_format .. debuffs_format
end

local function check_target_for_row_highlighting()
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

-- Player zone out packet
packets.incoming[0x00B]:register(function()
    zone_out_time = os.clock()
    zoning = true
end)

-- 0x0DF appears to change when player hp/mp/tp changes
packets.incoming[0x0DF]:register(function()
    update_party_name_hp_mp_tp_strings('both')
    update_party_debuff_strings('both')
end)

-- This seems to change when buffs on self change, also when party members zone
packets.incoming[0x037]:register(function()
    update_party_name_hp_mp_tp_strings('both')
    update_party_debuff_strings('both')
end)

-- Party member updates, joining/leaving party etc
packets.incoming[0x0DD]:register(function()
    update_party_name_hp_mp_tp_strings('both')
    update_party_debuff_strings('both')
end)

-- Party buffs update packet
packets.incoming[0x076]:register(function()
    update_party_debuff_strings('party_only')
end)

ui.display(function()
    if zoning and os.clock() > zone_out_time + zone_in_delay then
        zoning = false
    end
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

local function help()
    command.input('/echo Party Menu commands')
    command.input('/echo /pm h | help')
    command.input('/echo /pm t | tog | toggle')
    command.input('/echo /pm name | names')
    command.input('/echo /pm hp')
    command.input('/echo /pm mp')
    command.input('/echo /pm tp')
    command.input('/echo /pm db | debuff | debuffs')
    command.input('/echo /pm color')
    command.input('/echo /pm size [new_size]')
    command.input('/echo /pm pos | position [x] [y]')
    command.input('/echo /pm wid | width [new_width]')
    command.input('/echo /pm s | save')
end

pm:register('h', help)
pm:register('help', help)

local function toggle_ui()
    global_window_closed = not global_window_closed
end

pm:register('t', toggle_ui)
pm:register('tog', toggle_ui)
pm:register('toggle', toggle_ui)

local function toggle_name_display()
    options.names_visible = not options.names_visible
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('name', toggle_name_display)
pm:register('names', toggle_name_display)

local function toggle_hp_display()
    options.hp_mode_index = (options.hp_mode_index % #hp_modes) + 1
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('hp', toggle_hp_display)

local function toggle_mp_display()
    options.mp_mode_index = (options.mp_mode_index % #mp_modes) + 1
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('mp', toggle_mp_display)

local function toggle_tp_display()
    options.tp_visible = not options.tp_visible
    update_party_name_hp_mp_tp_strings('both')
end

pm:register('tp', toggle_tp_display)

local function toggle_debuff_display()
    options.debuffs_visible = not options.debuffs_visible
    update_party_debuff_strings('both')
end

pm:register('db', toggle_debuff_display)
pm:register('debuff', toggle_debuff_display)
pm:register('debuffs', toggle_debuff_display)

local function toggle_dynamic_coloring()
    options.dynamic_coloring = not options.dynamic_coloring
    update_party_name_hp_mp_tp_strings('both')
    if options.dynamic_coloring then
        command.input('/echo Coloring ON')
    else
        command.input('/echo Coloring OFF')
    end
end

pm:register('color', toggle_dynamic_coloring)

local function change_text_size(size)
    options.text_size = size
    update_party_name_hp_mp_tp_strings('both')
    update_party_debuff_strings('both')
    update_ui_dimensions()
end

-- Not sure what to put for maximum allowable values here
pm:register('size', change_text_size, '[size:integer(0,50)=20]')

local function change_position(x, y)
    options.global_window_state.x = x
    options.global_window_state.y = y
    update_ui_dimensions()
end
-- Not sure what to put for maximum allowable values here
pm:register('pos', change_position, '[x:integer(0,50000)=20]', '[y:integer(0,50000)=100]')
pm:register('position', change_position, '[x:integer(0,50000)=20]', '[y:integer(0,50000)=100]')

local function change_width(width)
    options.global_window_state.width = width
    update_ui_dimensions()
end

pm:register('wid', change_width, '[width:integer(0,50000)=500]')
pm:register('width', change_width, '[width:integer(0,50000)=500]')

local function save_settings()
    command.input('/echo Your party menu settings have been saved.')
    settings.save(options)
end

pm:register('s', save_settings)
pm:register('save', save_settings)

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
