local settings = require('settings')

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
                        { v = 1, r = 136, g = 179, b = 22, a = 255},
                        { v = 0.75, r = 204, g = 150, b = 57, a = 255},
                        { v = 0.5, r = 204, g = 97, b = 4, a = 255},
                        { v = 0.25, r = 224, g = 52, b = 0, a = 255},
                    },
                    show_percent = true,  
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
                { 
                    type = 'mp', 
                    colors = {
                        { v = 1, r = 184, g = 084, b = 121, a = 255}, 
                    },
                    show_percent = true,  
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
                { 
                    type = 'tp', 
                    colors = {
                        { v = 3, r = 255, g = 236, b = 35, a = 255}, 
                        { v = 2, r = 255, g = 236, b = 35, a = 255}, 
                        { v = 1, r = 255, g = 236, b = 35, a = 255}, 
                    },
                    show_percent = false, 
                    value_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
                    percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 
                },
            },
        },
        target = {
            pos = { x = -250, y = -300},
            width = 488,
            hide = false,
            colors = {
                { v = 1, r = 255, g = 20, b = 20, a = 255}, 
            },
            name_font = 'Roboto bold italic 12pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 10pt color:white stroke:"10% #000000BB"', 

            hide_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 11pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 11pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 11pt color:gray stroke:"10% #000000BB"',
        },
        subtarget = {
            pos = { x = -250, y = -325},
            width = 250,
            hide = false,
            colors = {
                { v = 1, r = 14, g = 87, b = 183, a = 255}, 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

            hide_action = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            action_font = 'Roboto bold 10pt color:white stroke:"10% #000000BB"', 
            complete_action_font = 'Roboto bold italic 10pt color:gray stroke:"10% #000000BB"',
            interrupted_action_font = 'Roboto bold italic strikethrough 10pt color:gray stroke:"10% #000000BB"',
        },
        focustarget = {
            pos = { x = -250, y = -350},
            width = 250,
            hide = false,
            complete_action_hold_time = 7,
            flash_cycle = { 0.3, 0.3 },
            colors = {
                { v = 1, r = 97, g = 25, b = 232, a = 255}, 
            },
            name_font = 'Roboto bold italic 11pt color:white stroke:"10% #000000BB"', 
            percent_font = 'Roboto bold italic 9pt color:white stroke:"10% #000000BB"', 

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