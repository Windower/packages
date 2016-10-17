-- inventory_service

require('string')
require('math')
require('pack')
read_container = require('reading')
res = read_container('resources_service')
packet = require('packet')
share_container = require('sharing')
bit = require('bit')

defaults = {}

monsters = share_container()
for i,v in pairs(defaults) do
    monsters[i] = v
end

function incoming(p)
    if p.injected then return end
end

packet.incoming:register(incoming)