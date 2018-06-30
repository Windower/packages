local chat = require('chat')
local command = require('command')
local ipc = require('ipc')
local player = require('player')

local send = command.new('send')

local send_msg = function(target, message)
    print('sending')
    ipc.send(target .. ' ' .. message)
end

send:register(send_msg, '<target:string(@?%a+)>', '<message:text>')

ipc.received:register(function(message)
    print(message)
    local target, text = message:match('(@?%a+) (.*)')
    if target == player.name or target == '@all' then
        local ok, error = pcall(command.input, text)
        if not ok then
            chat.add_text(error, 167)
        end
    end
end)