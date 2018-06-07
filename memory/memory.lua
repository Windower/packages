local types = require('memory:types')
local scanner = require('scanner')
local ffi = require('ffi')
require('string')

local scanned = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}

local byte_ptr = ffi.typeof('char**')

return setmetatable({}, {
    __index = function(_, name)
        local type = types[name]
        if type == nil then
            return nil
        end

        local base_ptr = scanned[name]
        if base_ptr == nil then

            -- TODO: Remove after scanner allows invalid sigs
            local ptr = scanner.scan(type.signature, name == 'auto_disconnect' and 'polcore.dll' or 'FFXiMain.dll')
            -- local ptr
            -- for _, module in ipairs(modules) do
            --     ptr = scanner.scan(type.signature)
            --     if ptr ~= nil then
            --         break
            --     end
            -- end
            assert(ptr ~= nil, 'Signature ' .. type.signature .. ' not found.')

            for _, offset in ipairs(type.static_offsets) do
                ptr = ffi.cast(byte_ptr, ptr)[offset]
            end

            base_ptr = ptr

            scanned[name] = base_ptr
        end

        local ptr = base_ptr
        for _, offset in ipairs(type.offsets) do
            ptr = ffi.cast(byte_ptr, ptr)[offset]
        end

        return ffi.cast(type.ctype, ptr)
    end,
})
