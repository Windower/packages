local settings = require('settings')
local ui = require('core.ui')

local defaults = {
    frames = {
        player = {
            pos = { x = 0, y = -260, x_anchor = 'center', y_anchor = 'bottom'},
            width = 450,
            show = true,
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
            pos = { x = 0, y = -320, x_anchor = 'center', y_anchor = 'bottom'},
            width = 500,
            show = true,
            colors = {
                [1] = ui.color.rgb(255, 20, 20, 255), 
            },
            name_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            show_distance = true,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            show_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            show_target_target = true,
            target_target_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            show_party_resources = false,
            party_resources_height = 2,

            show_action = true,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 11pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 11pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 11pt color:gray stroke:"10% #000000BB"',

            show_aggro = false,
            aggro_degrade_time = 10,
        },
        subtarget = {
            pos = { x = -125, y = -345, x_anchor = 'center', y_anchor = 'bottom'},
            width = 250,
            show = false,
            colors = {
                [1] = ui.color.rgb(14, 87, 183, 255), 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            show_distance = false,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            show_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            show_target_target = false,
            target_target_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            show_party_resources = false,
            party_resources_height = 2,

            show_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 10pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 10pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 10pt color:gray stroke:"10% #000000BB"',

            show_aggro = false,
            aggro_degrade_time = 10,
        },
        focustarget = {
            pos = { x = -125, y = -370, x_anchor = 'center', y_anchor = 'bottom'},
            width = 250,
            show = false,
            complete_action_hold_time = 7,
            colors = {
                [1] = ui.color.rgb(97, 25, 232, 255), 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            show_distance = false,
            distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            show_targeted = false,
            target_color = ui.color.rgb(255, 50, 50, 255),

            show_target_target = false,
            target_target_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            mp_color = ui.color.rgb(184, 084, 121, 255), 
            tp_color = ui.color.rgb(255, 236, 35, 255), 
            show_party_resources = false,
            party_resources_height = 2,

            show_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 10pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 10pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 10pt color:gray stroke:"10% #000000BB"',

            show_aggro = false,
            aggro_degrade_time = 10,
        },
        aggro = {
            pos = { x = 320, y = -360, x_anchor = 'center', y_anchor = 'bottom'},
            width = 170,
            show = false,
            entity_count = 8,
            entity_padding = 24,
            entity_order = 'low-high', -- 'high-low', 'near-far', 'far-near'
            entity_frame = {
                complete_action_hold_time = 7,
                colors = {
                    [1] = ui.color.rgb(0, 150, 50, 255), 
                },
                name_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

                show_distance = false,
                distance_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

                show_targeted = false,
                target_color = ui.color.rgb(255, 50, 50, 255),

                show_target_target = false,
                target_target_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

                show_action = false,
                complete_action_hold_time = 7,
                flash_cycle = { 0.3, 0.3 },
                action_font = 'Roboto bold 9pt color:white stroke:"10% #000000BB"', 
                complete_action_font = 'Roboto bold italic 9pt color:gray stroke:"10% #000000BB"',
                interrupted_action_font = 'Roboto bold italic strikethrough 9pt color:gray stroke:"10% #000000BB"',

                show_aggro = false,
                aggro_degrade_time = 10,
            }
        }
    },
}

return settings.load(defaults)