local command = require('core.command')
local entities = require('entities')
local packet = require('packet')
local player = require('player')

local assist_response = function (id)
    if entities:by_id(id) then
        packet.incoming[0x058]:inject{
            player_id = player.id,
            target_id = id,
            player_index = player.index,
        };
    end
end

command.new('set_target'):register(assist_response, '<id:number>')
