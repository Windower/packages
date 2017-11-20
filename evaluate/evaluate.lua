command = require('command')
require('table')
require('string')
event = require('event')

read_container = require('reading')
res = read_container('resources_service')
items = read_container('inventory_service')
equipment = read_container('equipment_service')
player = read_container('player_service')

function hand(source,rawstr)
    assert(loadstring(rawstr:gsub("/e ","")))()
end

command.register('e',hand,true)

player.new_event.stats:register(function(stats) print('stats', stats, (stats and stats.str or 'Nope')) end)
player.new_event.linkshell1:register(function(linkshell1) print('linkshell1',linkshell1,(linkshell1 and linkshell1.red) or 'Nope') end)
player.new_event.index:register(function(id) print('id',id) end)
