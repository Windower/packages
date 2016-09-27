require('io')
require('string')
share_container = require('sharing')
windower = require('windower')

resources = share_container()

for f in io.popen('dir "'..windower.addon_path..'\\res\\" /b'):lines() do
    f = f:sub(1,-5) -- Removes extension.
    local data = require('res.'..f)
    resources[f] = data
end