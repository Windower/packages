require('io')
require('string')
share_container = require('sharing_lib')

resources = share_container()

-- REVISIT : NEED A WAY TO GET THE ACTUAL DIRECTORY FOR EVERYONE
for f in io.popen([[dir "E:\Users\Peter\My Documents\GitHub\windower5\build\bin\debug\packages\resources_serv\res\" /b]]):lines() do
    f = f:sub(1,-5) -- Removes extension.
    local data = require('res.'..f)
    resources[f] = data
end