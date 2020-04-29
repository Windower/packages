local settings = require('settings')
local ui = require('core.ui')
local command = require('core.command')
local os = require('os')
local string = require('string')
local world = require('world')
local packets = require('packets')

local defaults = {
    x = 400,
    y = 0,
    text_style = 'Roboto bold 12px stroke:"10% #000000BB" background:"#000000FF"',
}

local options = settings.load(defaults)

local start_time = os.time()

local zone_timer = {
    move = false,
    state = {
        title = 'Zone Timer',
        style = 'chromeless',
        x = options.x,
        y = options.y,
        width=80,
        height=30,
        resizable = false,
        moveable = true,
        closable = false,
    },
}

world.zone_change:register(function()
    if not zone_timer.tractor then
        start_time = os.time()
    end

    zone_timer.tractor = false
end)
packets.outgoing[0x01A]:register(function(packet, info)
    if packet.action_category == 0x13 then
        zone_timer.tractor = true
    end
end)

local zt = command.new('zonetimer')
zt:register('move', function(command)
    local new_move = nil
    if command == nil or command == '' then
        new_move = not zone_timer.move
    else
        new_move = set('show','on','true','yes'):contains(command:lower())
    end
    zone_timer.move = new_move

    zone_timer.state.style = zone_timer.move and 'normal' or 'chromeless'

    options.x = zone_timer.state.x
    options.y = zone_timer.state.y

    settings.save()
end, '[visible:one_of(show,hide,on,off,true,false,yes,no)]')

zt:register('pos', function(x, y)
    zone_timer.state.x = x
    zone_timer.state.y = y

    options.x = x
    options.y = y

    settings.save()
end, '<x:number()> <y:number()>')

ui.display(function()
    local seconds = os.time() - start_time
    if zone_timer.move then
        zone_timer.state, zone_timer.closed = ui.window('zone_timer', zone_timer.state, function()
            ui.location(0, 0)

            ui.text(string.format('['..os.date('!%H:%M:%S', seconds)..']{%s}', options.text_style))
        end)
    else
        ui.location(options.x, options.y)

        ui.text(string.format('['..os.date('!%H:%M:%S', seconds)..']{%s}', options.text_style))
    end
end)