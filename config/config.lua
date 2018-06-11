local memory = require('memory')
local settings = require('settings')

local defaults = {
    gameplay = {
        auto_target = true,
        inventory = {
            sort = false,
            type = 1,
        },
    },
    graphics = {
        aspect_ratio = {
            auto = false,
            value = 1.778,
        },
        gamma_adjustment = {
            red = 1.5,
            green = 1.5,
            blue = 1.5,
        },
        framerate = 60,
        animation_framerate = 60,
        clipping_plane = 10,
    },
    audio = {
        volume = {
            effects = 1.0,
            music = 1.0,
        },
        footstep_effects = true,
    },
    system = {
        auto_disconnect = {
            enabled = false,
            time = 60,
        }
    },
}

local options = settings.load(defaults)

coroutine.schedule(function()
    while true do
        do -- misc2_graphics
            local struct = memory.misc2_graphics
            local options = options.graphics

            local aspect_ratio = options.aspect_ratio

            struct.render.aspect_ratio = (4 / 3) / (aspect_ratio.auto and (x / y) or aspect_ratio.value)
            struct.render.framerate_divisor = options.framerate == 'unlimited' and 0 or math.ceil(60 / options.framerate)
            struct.clipping_plane_entity = options.clipping_plane
            struct.clipping_plane_map = options.clipping_plane
        end

        do -- auto_disconnect
            local struct = memory.auto_disconnect
            local options = options.system
            
            local auto_disconnect = options.auto_disconnect

            struct.enabled = auto_disconnect.enabled
            struct.timeout_time = auto_disconnect.time
        end

        do -- gamma_adjustment
            local struct = memory.gamma_adjustment
            local options = options.graphics

            local gamma_adjustment = options.gamma_adjustment

            struct.red = gamma_adjustment.red
            struct.green = gamma_adjustment.green
            struct.blue = gamma_adjustment.blue
        end

        coroutine.sleep_frame()
    end
end)
