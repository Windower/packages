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

local to_color = function (color_settings)
    return ui.color.rgb(color_settings.r,
                        color_settings.g,
                        color_settings.b,
                        color_settings.a)
end

local color_from_value = function(value, colors)
    local max = 0, color
    for _, c in ipairs(colors) do
        if c.v >= value and c.v > max then
            color = c
        end
    end
    return color
end

return {
    convert_to_pixel_space = convert_to_pixel_space,
    init_frame_positions = init_frame_positions,
    to_color = to_color,
    color_from_value = color_from_value,
}