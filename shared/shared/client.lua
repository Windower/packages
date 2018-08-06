local ffi = require('ffi')
local shared = require('shared')
local structs = require('structs')

local ffi_cast = ffi.cast
local ffi_cdef = ffi.cdef

local prepared = {}

local prepare_struct
prepare_struct = function(struct)
    for label, field in pairs(struct.fields) do
        local ftype = field.type
        if ftype and ftype.fields then
            prepare_struct(ftype)
        end
    end

    local name = struct.name
    if prepared[name] then
        return
    end

    ffi_cdef('typedef ' .. struct.cdef .. ' ' .. name .. ';')
    structs.metatype(struct)

    prepared[name] = true
end

return {
    new = function(service_name, name)
        name = name or 'data'

        local data_client = shared.get(service_name, service_name .. '_' .. name)
        local data = data_client:read()

        local struct = data.struct
        prepare_struct(struct)

        return ffi_cast(struct.name .. '*', data.ptr)[0]
    end,
}
