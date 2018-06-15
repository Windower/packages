local ffi = require('ffi')
local scanner = require('scanner')
local string = require('string')
local types = require('memory:types')

local scan_results = {}
local fixed_types = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}
local byte_ptr = ffi.typeof('char**')

local meta_array
local meta_struct

local do_get_magic
do_get_magic = function(instance, type)
    if type.ptr == true then
        return do_get_magic(instance[0], type.base)
    elseif type.count ~= nil and type.cdef ~= 'char' then
        return setmetatable({ cdata = instance, type = type.base }, meta_array)
    elseif type.fields ~= nil then
        return setmetatable({ cdata = instance, type = type }, meta_struct)
    else
        local tolua = type.tolua
        local data = type.signature ~= nil and instance[0] or instance
        return tolua and tolua(data) or data
    end
end

local do_set_magic = function(root_instance, index, value, type)
    local toc = type.toc
    if toc ~= nil then
        toc(root_instance, index, value)
    else
        root_instance[index] = value
    end
end

meta_array = {
    __index = function(data, index)
        local instance = data.cdata[index]
        return do_get_magic(instance, data.type)
    end,
    __newindex = function(data, index, value)
        do_set_magic(data.cdata, index, value, data.type)
    end,
}

do
    local get_struct_field = function(fields, name)
        for _, field in ipairs(fields) do
            if field.label == name then
                return field
            end
        end

        error('Nested memory definition for \'' .. name .. '\' not found.')
    end

    meta_struct = {
        __index = function(data, name)
            local instance = data.cdata[name]
            local field = get_struct_field(data.type.fields, name)
            return do_get_magic(instance, field.type)
        end,
        __newindex = function(data, name, value)
            local field = get_struct_field(data.type.fields, name)
            do_set_magic(data.cdata, name, value, field.type)
        end,
    }
end

local get_instance = function(type, ptr)
    return ffi.cast(type.ctype, ptr)
end

local setup_name = function(name)
    local type = types[name]
    assert(type ~= nil, 'Memory definition for \'' .. name .. '\' not found.')

    local ptr = scan_results[name]
    if ptr == nil then
        for _, module in ipairs(modules) do
            ptr = scanner.scan(type.signature, module)
            if ptr ~= nil then
                break
            end
        end
        assert(ptr ~= nil, 'Signature ' .. type.signature .. ' not found.')

        for _, offset in ipairs(type.static_offsets) do
            ptr = ffi.cast(byte_ptr, ptr)[offset]
        end

        scan_results[name] = ptr
    end

    return type, ptr
end

return setmetatable({}, {
    __index = function(_, name)
        do
            local cached = fixed_types[name]
            if cached ~= nil then
                return do_get_magic(cached, types[name])
            end
        end

        local type, ptr = setup_name(name)

        if next(type.offsets) == nil then
            local res = get_instance(type, ptr)
            fixed_types[name] = res
            return do_get_magic(res, type)
        end

        for _, offset in ipairs(type.offsets) do
            ptr = ffi.cast(byte_ptr, ptr)[offset]
        end

        return do_get_magic(get_instance(type, ptr), type)
    end,
    __newindex = function(_, name, value)
        if value.signature then
            types[name] = value
            return
        end

        do
            local cached = fixed_types[name]
            if cached ~= nil then
                return do_set_magic(cached, 0, value, types[name])
            end
        end

        local type, ptr = setup_name(name)

        do_set_magic(get_instance(type, ptr), 0, value, type)
    end,
})
