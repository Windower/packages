local shared = require('shared')

id_map = shared.get('client_data_service', 'id_map')

local dat_file = setmetatable({}, {
    __index = function(_, id)
        return id_map:read(id)
    end,
    __newindex = error,
    __metatable = false,
})

return dat_file
