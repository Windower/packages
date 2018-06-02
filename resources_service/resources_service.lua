require('table')
require('io')
local shared = require('shared')
local windower = require('windower')

resources = shared.new('resources')

resources.data = {}

--TODO: Temporary....
for path in io.popen('dir "' .. windower.addon_path .. '\\res\\" /s/b'):lines() do
    local res, slot_table = dofile(path)
    local res_name = path:match('\\([%a_]+.lua)'):sub(1, -5)
    resources.data[res_name] = res
end

local remap = {
    en = 'english',
    jp = 'japanese',
    ens = 'english_short',
    jps = 'japanese_short',
    enl = 'english_log',
    jpl = 'japanese_log',
}

-- Set id property and adjust language identifiers of each resource entry
for _, resource in pairs(resources.data) do
    for id, entry in pairs(resource) do
        for from, to in pairs(remap) do
            entry[to] = entry[from]
            entry[from] = nil
        end
    end
end

resources.env = {
    pairs = pairs,
    next = next,
    table = table,
}
