local windower = require('windower')
local ui = require('core.ui')

local convert_to_pixel_space = function(x, y)
    if x < 0 then
        x = windower.settings.ui_size.width + x
    elseif x <= 1 then
        x = windower.settings.ui_size.width * x
    end

    if y < 0 then
        y = windower.settings.ui_size.height + y
    elseif y <= 1 then
        y = windower.settings.ui_size.height * y
    end

    return x, y
end

local init_frame_positions = function(frames, options)
    for name, frame in pairs(frames) do
        frame.x, frame.y = convert_to_pixel_space(options.frames[name].pos.x, options.frames[name].pos.y)
    end
end

local to_color = function (color_settings)
    return ui.color.rgb(color_settings.r,
                        color_settings.g,
                        color_settings.b,
                        color_settings.a)
end

return {
    convert_to_pixel_space = convert_to_pixel_space,
    init_frame_positions = init_frame_positions,
    to_color = to_color,
}