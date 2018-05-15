local command = require('command')
local ffi = require('ffi')

ffi.cdef[[
    bool TerminateProcess(void* hProcess, uint32_t uExitCode);
]]

local kernel32 = ffi.load('kernel32')

command.register('terminate', function() 
    kernel32.TerminateProcess(ffi.cast('void*',-1), 0)
end)
