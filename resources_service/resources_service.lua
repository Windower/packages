local shared = require('shared')

resources = shared.new('resources')

local remap = {
    en = 'english',
    jp = 'japanese',
    ens = 'english_short',
    jps = 'japanese_short',
    enl = 'english_log',
    jpl = 'japanese_log',
}

resources.data = setmetatable({}, {
    __index = function(t, k)
        local resource = require('resources_data:' .. k)
        t[k] = resource

        -- Set id property and adjust language identifiers of each resource entry
        for id, entry in pairs(resource) do
            for from, to in pairs(remap) do
                entry[to] = entry[from]
                entry[from] = nil
            end
        end

        return resource
    end,
})

resources.env = {
    next = next,
}
