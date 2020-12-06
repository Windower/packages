local os = require("os")
local set = require("set")
local player = require("player")
local packet = require("packet")
local equipment = require("equipment")
local status_effects = require("status_effects")

local o = {
    fire = 0,
    earth = 0,
    water = 0,
    wind = 0,
    ice = 0,
    thunder = 0,
    light = 0,
    dark = 0,
}
local burden = {}

local mt = {
    __index = burden
}
setmetatable(o, mt)

local updaters = {}

local heatsink = false
local count_to_decay_rate = {
    [0] = 2,
    [1] = 4,
    [2] = 5,
    [3] = 6,
}

function burden.update_decay_rate()
    if heatsink then
        local count = 0
        water_maneuvers = status_effects.party[0].effects[305]
        burden.decay_rate = count_to_decay_rate[water_maneuvers]
    else
        burden.decay_rate = 1
    end
end

status_effects.gained:register(burden.update_decay_rate)
status_effects.lost:register(burden.update_decay_rate)

packet.incoming[0x044][0x012]:register(function(data)
    for _, attachment in pairs(data.attachments) do
        heatsink = attachment == 162
        if heatsink then
            break
        end
    end
    burden.update_decay_rate()
end)

local thresholdModifiers =
{
    [11101] = 40, -- Cirque Farsetto +2
    [11201] = 20, -- Cirque Farsetto +1
    [14930] = 5,  -- Pup. Dastanas
    [15030] = 5,  -- Pup. Dastanas +1
    [16281] = 5,  -- Buffoon's Collar
    [16282] = 5,  -- Buffoon's Collar +1
    [20520] = 40, -- Midnights
    [26263] = 10, -- Visucius's Mantle
    [26932] = 40, -- Kara. Farsetto
    [26933] = 40, -- Kara. Farsetto +1
    [27960] = 5,  -- Foire Dastanas
    [27981] = 5,  -- Foire Dastanas +1
    [28634] = 5,  -- Dispersal Mantle
}
burden.threshold = 30

local pet_actions = {
    [136] = "activate",
    [139] = "deactivate",
    [141] = "fire",
    [142] = "ice",
    [143] = "wind",
    [144] = "earth",
    [145] = "thunder",
    [146] = "water",
    [147] = "light",
    [148] = "dark",
    [309] = "cooldown",
    [310] = "deus_ex_automata",
}

local maneuvers = set(
    141,
    142,
    143,
    144,
    145,
    146,
    147,
    148
)

function burden:update(action)
    updaters[action](self)
end

function burden:zone()
    for k in pairs(self) do
        self[k] = 15
    end
end

function burden.set_decay_event(func)
    burden.decay_event = func
end

function updaters.deactivate(self)
    for k in pairs(self) do
        self[k] = 0
    end
end

function updaters.activate(self)
    burden.update_decay_rate()
    for k in pairs(self) do
        self[k] = 15
    end
end
updaters.deus_ex_automata = updaters.activate

function updaters.cooldown(self)
    for k in pairs(self) do
        self[k] = self[k] / 2
    end
end

function updaters.maneuver(self, type)
    self[type] = self[type] + 15

    burden.threshold = 30
    for _, slot in pairs(equipment) do
        burden.threshold = burden.threshold + (thresholdModifiers[slot.item.id] or 0)
    end
end

function updaters.ice(self) updaters.maneuver(self, "ice") end
function updaters.fire(self) updaters.maneuver(self, "fire") end
function updaters.wind(self) updaters.maneuver(self, "wind") end
function updaters.dark(self) updaters.maneuver(self, "dark") end
function updaters.earth(self) updaters.maneuver(self, "earth") end
function updaters.water(self) updaters.maneuver(self, "water") end
function updaters.light(self) updaters.maneuver(self, "light") end
function updaters.thunder(self) updaters.maneuver(self, "thunder") end

burden.decay_rate = 1
function burden.decay()
    for k in pairs(o) do
        if o[k] > burden.decay_rate then
            o[k] = o[k] - burden.decay_rate
        elseif o[k] > 0 then
            o[k] = 0
        end
    end
end

function tick()
    next_tick = os.time() + (os.time() % 3)
    while(true) do
        if os.time() >= next_tick then
            next_tick = os.time() + 3
            burden.decay()
        end
        coroutine.sleep_frame()
    end
end
coroutine.schedule(tick)

local process_action = function(act)
    if player.main_job_id ~= 18 then
        return
    end
    if act.category == 6 and act.actor == player.id and pet_actions[act.param] then
        o:update(pet_actions[act.param]) -- Always assumes good burden (+15).
        if maneuvers:contains(act.param) then
            if act.targets[1].actions[1].param > 0 then
                o[pet_actions[act.param]] = burden.threshold + act.targets[1].actions[1].param -- Corrects for bad burden when over threshold.
            end
        end
    end
end
packet.incoming[0x028]:register(process_action)

packet.incoming[0x00B]:register(function()
    o:zone()
end)

return o
