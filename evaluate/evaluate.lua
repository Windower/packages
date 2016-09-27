command = require('command')
require('table')
require('string')

read_container = require('reading_lib')
res = read_container('resources_serv')
items = read_container('inventory_serv')
equipment = read_container('equipment_serv')
player = read_container('player_serv')

function hand(source,rawstr)
	assert(loadstring(rawstr:gsub("/e ","")))()
end

command.register('e',hand,true)