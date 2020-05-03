local string = require('string')
local windower = require('windower')
local ui = require('core.ui')

local convert_to_pixel_space = function(pos, width, height)
    local x = pos.x
    if pos.x_anchor == 'center' then
        x = (windower.settings.ui_size.width / 2) - (width / 2) + pos.x
    elseif pos.x_anchor == 'right' then
        x = windower.settings.ui_size.width - width + pos.x
    end
    local y = pos.y
    if pos.y_anchor == 'center' then
        y = (windower.settings.ui_size.height / 2) - (height / 2) + pos.y
    elseif pos.y_anchor == 'bottom' then
        y = windower.settings.ui_size.height - height + pos.y
    end
    return x, y
end

local init_frame_positions = function(frames, options)
    for name, frame in pairs(frames) do
        local width = options.frames[name].width or frames[name].width or frames[name].max_width
        local height = options.frames[name].height or frames[name].height or frames[name].max_height
        frame.x, frame.y = convert_to_pixel_space(options.frames[name].pos, width, height)
    end
end

local color_from_value = function(value, colors)
    local max = 99999, color
    for v, c in pairs(colors) do
        if value <= v and max > v - value then
            color = c
            max = v - value
        end
    end
    return color
end

function ui_table(t, x_offset, y_offset)
    for key, value in pairs(t) do
        if type(value) == 'boolean' then
            ui.location(x_offset, y_offset)
            t[key] = ui.check(key, tostring(key), value)
            y_offset = y_offset + 24
        elseif type(value) == 'string' then
            ui.location(x_offset, y_offset)
            ui.text(tostring(key))
            ui.location(x_offset + 70, y_offset)
            t[key] = ui.edit(key, value)
            y_offset = y_offset + 24
        elseif type(value) == 'number' then
            ui.location(x_offset, y_offset)
            ui.text(tostring(key))
            ui.location(x_offset + 70, y_offset)
            t[key] = tonumber(ui.edit(key, tostring(value)))
            y_offset = y_offset + 24
        elseif type(value) == 'table' then
            ui.location(x_offset, y_offset)
            ui.text(tostring(key))
            x_offset = x_offset + 25
            t[key], x_offset, y_offset = ui_table(value, x_offset, y_offset)
            x_offset = x_offset - 25
        end
    end

    return t, x_offset, y_offset
end

local short_letters = 'liI1 -\'".,'
local wide_letters = 'wWmMAKkgG'
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

return {
    convert_to_pixel_space = convert_to_pixel_space,
    init_frame_positions = init_frame_positions,
    to_color = to_color,
    color_from_value = color_from_value,
    ui_table = ui_table,
    calculate_text_size_terribly = calculate_text_size_terribly,
}