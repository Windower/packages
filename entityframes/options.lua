local settings = require('settings')
local ui = require('core.ui')

local defaults = {
    frames = {
        player = {
            pos = { x = 0.5, y = -260},
            width = 500,
            hide = false,
            bars = {
                { 
                    type = 'hp', 
                    colors = {
                        [1] = ui.color.rgb(136, 179, 22, 255),
                        [0.75] = ui.color.rgb(204, 150, 57, 255),
                        [0.5] = ui.color.rgb(204, 97, 4, 255),
                        [0.25] = ui.color.rgb(224, 52, 0, 255),
                    },
                    show_percent = true,  
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
                { 
                    type = 'mp', 
                    colors = {
                        [1] = ui.color.rgb(184, 084, 121, 255), 
                    },
                    show_percent = true,  
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
                { 
                    type = 'tp', 
                    colors = {
                        [3] = ui.color.rgb(255, 236, 35, 255), 
                        [2] = ui.color.rgb(255, 236, 35, 255), 
                        [1] = ui.color.rgb(255, 236, 35, 255), 
                    },
                    show_percent = false, 
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
            },
        },
        target = {
            pos = { x = -250, y = -320},
            width = 500,
            hide = false,
            colors = {
                [1] = ui.color.rgb(255, 20, 20, 255), 
            },
            name_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            hide_distance = false,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            hide_target_target = false,
            target_target_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            hide_party_resources = true,
            party_resources_height = 2,

            hide_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 11pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 11pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 11pt color:gray stroke:"10% #000000BB"',
        },
        subtarget = {
            pos = { x = -250, y = -345},
            width = 250,
            hide = false,
            colors = {
                [1] = ui.color.rgb(14, 87, 183, 255), 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_distance = false,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            hide_target_target = false,
            target_target_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            hide_party_resources = true,
            party_resources_height = 2,

            hide_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 10pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 10pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 10pt color:gray stroke:"10% #000000BB"',
        },
        focustarget = {
            pos = { x = -250, y = -370},
            width = 250,
            hide = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            colors = {
                [1] = ui.color.rgb(97, 25, 232, 255), 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_distance = false,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            hide_target_target = false,
            target_target_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            hide_party_resources = true,
            party_resources_height = 2,

            hide_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 10pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 10pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 10pt color:gray stroke:"10% #000000BB"',
        },
    },
}

return settings.load(defaults)