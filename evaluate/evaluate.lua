command = require('command')

function hand(source,rawstr)
    assert(loadstring(rawstr:gsub("/e ","")))()
end

command.register('e',hand,true)
