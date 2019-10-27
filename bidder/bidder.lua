local command     = require('core.command')
local string      = require('string')
local tolog       = require('core.chat').add_text

local client_data = require('client_data')
local items       = require('items')
local packets     = require('packets')
local resources   = require('resources')

local line_divider = function(color)
    tolog(('-'):rep(62), color or nil)
end

local user_error = function(message, syntax)
    line_divider(55)
    tolog((' '):rep(20) ..'-= Bidder: Command Error =-', 255)
    line_divider(55)
    if syntax then
        tolog((' '):rep(12) ..'"/ah buy|sell <item> <stack> <price>"', 255)
        tolog('')
    end
    tolog(message, 255)
    line_divider(55)
end

local mog_house = command.new('mh')
mog_house:register(function() packets.incoming[0x02e]:inject() end)

local mailbox = function(directory)
    packets.incoming[0x04b][directory]:inject({
        delivery_slot = 255,
        _known1       = 255,
        _known2       = 255,
        _known3       = 4294967295,
        success       = 1,
    })
end

local outbox = command.new('outbox')
outbox:register(function() mailbox(0x0d) end)

local inbox = command.new('inbox')
inbox:register(function() mailbox(0x0e) end)

local auction_house = command.new('ah')
auction_house:register('open', function()
    packets.incoming[0x04c][0x02]:inject({
        sale_slot     = 255,
        packet_number = 1,
        _known1       = 0,
    })
end)

auction_house:register('status', function()
    packets.incoming[0x04c][0x02]:inject({
        sale_slot     = 255,
        packet_number = 1,
        _known1       = 0,
    })
    packets.incoming[0x04c][0x05]:inject({
        type          = 5,
        sale_slot     = -1,
        packet_number = 1,
        _known1       = 0,
    })
end)

local auction_bid, auction_sale
do
    local checks = {
        [1] = function(item)
            item = client_data.items:by_name(item)
            if not item[1] then
                item = 'Failed to look up <item>. Please check and try again.'
            else
                item = item[1].id
            end

            return item
        end,

        [2] = function(stack)
            if stack:match('0') then
                stack = true
            elseif stack:match('1') then
                stack = false
            else
                stack = 'The argument <stack> must be "0" for a single or "1" for a stack.'
            end

            return stack
        end,

        [3] = function(price)
            price = price:gsub('%,',''):gsub('%.','')
            price = tonumber(price)
            if not price then
                price = 'The argument <price> must be a number. Periods and commas allowed.'
            end

            return price
        end,
    }

    auction_bid = function(...)
        local args = {...}
        if #args < 3 or #args > 3 then
            return user_error('Invalid number of arguments. Got '..#args..'. Expected 3.', true)
        end

        local item_string = args[1]

        for i, v in ipairs(args) do
            local result = checks[i](v)
            if type(result) == 'string' then
                return user_error(result)
            end
            args[i] = result
        end

        if args[2] == false and resources.items[args[1]].stack == 1 then
            return user_error(item_string ..' is only availible in single quantity.')
        end

        packets.outgoing[0x04e][0x0e]:inject({
            sale_slot = 7,
            item_id   = args[1],
            stack     = args[2],
            price     = args[3],
        })
    end

    auction_sale = function(...)
        local args = {...}
        if #args < 3 or #args > 3 then
            return user_error('Invalid number of arguments. Got '..#args..'. Expected 3.', true)
        end

        local item_string = args[1]

        for i, v in ipairs(args) do
            local result = checks[i](v)
            if type(result) == 'string' then
                return user_error(result)
            end
            args[i] = result
        end

        if args[2] == false and resources.items[args[1]].stack == 1 then
            return user_error(item_string ..' is only availible in single quantity.')
        end

        local inventory = items.bags[0]
        for _ in ipairs(inventory) do
            local _ = inventory[_]
            if _.id == item then
                if stack then
                    if _.count == _.item.stack then
                        args[4] = _.index
                    end
                else
                    args[4] = _.index
                end
            end
        end

        if not args[4] then
            return user_error('Failed to find item(s). Check spelling and/or inventory then try again.', true)
        end

        packets.outgoing[0x04e][0x04]:inject({
            sale_slot = 0,
            item_id   = args[1],
            stack     = args[2],
            price     = args[3],
            bag_index = args[4],
        })

        packets.outgoing[0x04e][0x0b]:inject({
            sale_slot = 0,
            stack     = args[2],
            price     = args[3],
            bag_index = args[4],
        })
    end
end

auction_house:register('buy', auction_bid,'[item:string]','[stack:string]','[price:string]')
auction_house:register('sell', auction_sale,'[item:string]','[stack:string]','[price:string]')

local help_text = command.new('bidder')
help_text:register(function()
    local _ = ' '
    line_divider(55)
    tolog((_):rep(20) ..'-= Bidder: Command Help =-', 255)
    line_divider(55)
    tolog((_):rep(8) ..'"/ah open"', 255)
    tolog((_):rep(12) ..'* Open the auction house menu.', 255)
    tolog((_):rep(8) ..'"/ah status"', 255)
    tolog((_):rep(12) ..'* Open sale status menu.', 255)
    tolog('')
    tolog((_):rep(8) ..'"/ah buy|sell <item> <stack> <price>"', 255)
    tolog((_):rep(12) ..'* <item> name of item (case sensitive).', 255)
    tolog((_):rep(12) ..'* <stack> "0" for single, "1" for stack.', 255)
    tolog((_):rep(12) ..'* <price> number, can include periods and commas.', 255)
    tolog('')
    tolog((_):rep(8) ..'"/inbox"', 255)
    tolog((_):rep(12) ..'* Open your delivery box menu.', 255)
    tolog((_):rep(8) ..'"/outbox"', 255)
    tolog('            * Open your outbox menu.', 255)
    tolog('')
    tolog((_):rep(8) ..'"/mh"', 255)
    tolog((_):rep(12) ..'* Open your mog-house menu.', 255)
    line_divider(55)
end)

--[[
Copyright © 2019, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
