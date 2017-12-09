require('table')
require('io')
local shared = require('shared')
local windower = require('windower')

resources = shared.new('resources')

resources.data = {}

--TODO: Temporary....
for path in io.popen('dir "' .. windower.addon_path .. '\\res\\" /s/b'):lines() do
    print('Loading...', path)
    local res, slot_table = dofile(path)
    local res_name = path:match('\\([%a_]+.lua)'):sub(1, -5)
    print('Matched:', res_name)
    resources.data[res_name] = res
end

-- Set id property and adjust language identifiers of each resource entry
for _, resource in pairs(resources.data) do
    for id, entry in pairs(resource) do
        entry.id = id
        entry.english = entry.en
        entry.japanese = entry.jp
        entry.en = nil
        entry.jp = nil
    end
end

resources.env = {
    pairs = pairs,
    next = next,
    table = table,
}
