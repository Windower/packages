local windower = require('windower')
local ui = require('core.ui')

local convert_to_pixel_space = function(x, y, width, height)
    if x < 0 then
        x = windower.settings.ui_size.width / 2 + x
    elseif x <= 1 then
        x = windower.settings.ui_size.width * x - width / 2
    end

    if y < 0 then
        y = windower.settings.ui_size.height + y - height
    elseif y <= 1 then
        y = windower.settings.ui_size.height * y - height / 2
    end

    return x, y
end

local init_frame_positions = function(frames, options)
    for name, frame in pairs(frames) do
        local width = options.frames[name].width or frames[name].width or frames[name].max_width
        local height = options.frames[name].height or frames[name].height or frames[name].max_height
        frame.x, frame.y = convert_to_pixel_space(options.frames[name].pos.x, options.frames[name].pos.y, width, height)
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

return {
    convert_to_pixel_space = convert_to_pixel_space,
    init_frame_positions = init_frame_positions,
    to_color = to_color,
    color_from_value = color_from_value,
    ui_table = ui_table,
}