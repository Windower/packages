local types = require('memory:types')
local scanner = require('scanner')
local ffi = require('ffi')
require('string')

local scanned = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}

return setmetatable({}, {
    __index = function(_, name)
        local info = scanned[name]
        if info == nil then
            local type = types[name]
            if type == nil then
                return nil
            end

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

            info = {
                data = ffi.cast(type.cdef .. ('*'):rep(type.dereference), ptr),
                dereference = type.dereference,
            }

            scanned[name] = info
        end

        local ptr = info.data
        for i = 1, info.dereference do
            ptr = ptr[0]
        end

        return ptr
    end,
})
