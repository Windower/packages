command = require('command')
require('table')
require('string')

read_container = require('reading')
res = read_container('resources_service')
items = read_container('inventory_service')
equipment = read_container('equipment_service')
player = read_container('player_service')

function hand(source,rawstr)
	assert(loadstring(rawstr:gsub("/e ","")))()
end

command.register('e',hand,true)