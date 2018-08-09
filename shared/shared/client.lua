local ffi = require('ffi');
local shared = require('shared')
local structs = require('structs')

local ffi_cast = ffi.cast
local ffi_cdef = ffi.cdef

local prepared = {}

local prepare_struct
local prepare_array

local setup_ftype = function(ftype)
    if ftype.count then
        prepare_array(ftype)
    elseif ftype.fields then
        prepare_struct(ftype)
    end

    local name = ftype.name
    if not name or prepared[name] then
        return
    end

    if ftype.fields then
        structs.name(ftype)
        structs.metatype(ftype)
    end

    prepared[name] = true
end

prepare_struct = function(struct)
    for label, field in pairs(struct.fields) do
        local ftype = field.type
        if ftype then
            setup_ftype(ftype)
        end

        local lookup = field.lookup
        if type(lookup) == 'function' then
            setfenv(lookup, _G)
        end
    end
end

prepare_array = function(array)
    local ftype = array.base
    if ftype then
        setup_ftype(ftype)
    end
end

return {
    new = function(service_name, name)
        name = name or 'data'

        local data_client = shared.get(service_name, service_name .. '_' .. name)
        local data = data_client:read()

        local ftype = data.ftype
        setup_ftype(ftype)

        return structs.from_ptr(ftype, data.ptr), ftype
    end,
}
