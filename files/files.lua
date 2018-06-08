require('io')

local files = {}

local file_mt = {
    __index = files,
}

files.create = function(path)
    return setmetatable({path = path}, file_mt)
end

files.exists = function(file)
    local f = io.open(file.path, 'r')
    local exists = f ~= nil

    if exists then
        f:close()
    end

    return exists
end

files.read = function(file)
    local f = io.open(file.path, 'r')
    local contents = f:read("*a")
    f:close()
    return contents
end

files.write = function(file, str)
    local f = io.open(file.path, 'w')
    f:write(str)
    f:close()
end

files.append = function(file, str, newline)
    newline = newline ~= false

    local f = io.open(file.path, 'a')
    f:write(str)
    if newline then
        f:write('\n')
    end
    f:close()
end

return files
