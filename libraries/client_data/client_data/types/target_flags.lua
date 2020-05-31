local struct = require('struct')

return struct.struct({
    player          = {0x00, struct.boolbit(struct.uint8), offset = 0},
    pet             = {0x00, struct.boolbit(struct.uint8), offset = 1},
    party           = {0x00, struct.boolbit(struct.uint8), offset = 2},
    pc              = {0x00, struct.boolbit(struct.uint8), offset = 3},
    npc             = {0x00, struct.boolbit(struct.uint8), offset = 4},
    enemy           = {0x00, struct.boolbit(struct.uint8), offset = 5},
    object          = {0x00, struct.boolbit(struct.uint8), offset = 6},
    dead            = {0x00, struct.boolbit(struct.uint8), offset = 7},
})
