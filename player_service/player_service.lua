-- inventory_service

require('string')
require('math')
require('pack')
read_container = require('reading')
res = read_container('resources_service')
packet = require('packet')
share_container = require('sharing')
bit = require('bit')

res_cache = {
    spell_keys = res.spells:keys(),
    job_ability_keys = res.job_abilities:keys(),
    jobs_keys = res.jobs:keys(),
    }

defaults = {}

defaults.id = -1
defaults.index = -1

function index_stats(t,k)
    if type(k) == 'string' and rawget(t,k..'_Base') then
        -- So STR returns the total STR but doesn't need to be continuously adjusted
        return rawget(t,k..'_Base')+rawget(t,k..'_Added')
    end
    return rawget(t,k)
end
defaults.stats = {
    HP_Max=1,
    HP_Current=1,
    HPP=100,
    MP_Max=1,
    MP_Current=1,
    MPP=100,
    TP=0,
    STR_Base=0,
    STR_Added=0,
    DEX_Base=0,
    DEX_Added=0,
    VIT_Base=0,
    VIT_Added=0,
    AGI_Base=0,
    AGI_Added=0,
    INT_Base=0,
    INT_Added=0,
    MND_Base=0,
    MND_Added=0,
    CHR_Base=0,
    CHR_Added=0,
    Attack=0,
    Defense=0,
    Fire_Resistance=0,
    Ice_Resistance=0,
    Wind_Resistance=0,
    Earth_Resistance=0,
    Lightning_Resistance=0,
    Water_Resistance=0,
    Light_Resistance=0,
    Dark_Resistance=0,
    }
setmetatable(defaults.stats,{__index=index_stats})
    
defaults.known_spells = {}
defaults.available_spells = {}
for _,v in ipairs(res_cache.spell_keys) do
    defaults.known_spells[v] = false
    defaults.available_spells[v] = false
end

defaults.available_abilities = {}
for _,v in ipairs(res_cache.job_ability_keys) do
    defaults.available_abilities = false
end

defaults.buffs = {}
function buff_duration(t)
    return math.max(rawget(t,'ts')-os.time(),0)
end
for i=1,32 do
    defaults.buffs = setmetatable({id=0,ts=-1},{duration=buff_duration})
end

defaults.job_levels = {}
for _,v in ipairs(res_cache.jobs_keys) do
    defaults.job_levels[res.jobs[v].ens] = 0
end

defaults.merits = {}
-- Need to implement

defaults.job_points = {__raw={},__current={}}
function index_job_points(t,k)
    if type(k) == 'string' then
        local job = res.jobs:with('en',k)
        if job then
            -- Assemble a table of job points for that job and return it
            local tab = {total = 0,current = rawget(t,__current)[job.id]}
            for i=job.id*64,job.id*64-2,2 do
                if res.job_points[i] then
                    tab[res.job_points[i].en] = rawget(t,'__raw')[i]
                    tab.total = tab.total + tab[res.job_points[i].en]
                end
            end
            return tab
        elseif res.job_points:with('en',k) then
            return rawget(t,'__raw')[res.job_points:with('en',k).id]
        end
    end
    return rawget(t,'__raw')[k]
end
setmetatable(defaults.job_points,{__index=index_job_points})

player = share_container()
for i,v in pairs(defaults) do
    player[i] = v
end

function incoming(p)
    if p.injected then return end
    if p.id == 0x00A then
        player.id                           = p.data:unpack('I',0x01)
        player.index                        = p.data:unpack('H',0x05)
        player.stats.STR_Base               = p.data:unpack('H',0xC9)
        player.stats.DEX_Base               = p.data:unpack('H',0xCB)
        player.stats.VIT_Base               = p.data:unpack('H',0xCD)
        player.stats.AGI_Base               = p.data:unpack('H',0xCF)
        player.stats.INT_Base               = p.data:unpack('H',0xD1)
        player.stats.MND_Base               = p.data:unpack('H',0xD3)
        player.stats.CHR_Base               = p.data:unpack('H',0xD5)
        player.stats.STR_Added              = p.data:unpack('H',0xD7)
        player.stats.DEX_Added              = p.data:unpack('H',0xD9)
        player.stats.VIT_Added              = p.data:unpack('H',0xDB)
        player.stats.AGI_Added              = p.data:unpack('H',0xDD)
        player.stats.INT_Added              = p.data:unpack('H',0xDF)
        player.stats.MND_Added              = p.data:unpack('H',0xE1)
        player.stats.CHR_Added              = p.data:unpack('H',0xE3)
        player.stats.HP_Max                = p.data:unpack('I',0xE5)
        player.stats.MP_Max                = p.data:unpack('I',0xE9)
    elseif p.id == 0x01B then
        player.stats.STR_Base               = p.data:unpack('H',0x1D)
        player.stats.DEX_Base               = p.data:unpack('H',0x1F)
        player.stats.VIT_Base               = p.data:unpack('H',0x21)
        player.stats.AGI_Base               = p.data:unpack('H',0x23)
        player.stats.INT_Base               = p.data:unpack('H',0x25)
        player.stats.MND_Base               = p.data:unpack('H',0x27)
        player.stats.CHR_Base               = p.data:unpack('H',0x29)
        
        for i=1,res.jobs:len() do
            player.job_levels[res.jobs[i]]  = p.data:byte(i+68)
        end
    elseif p.id == 0x037 then
        player.stats.HPP                    = p.data:byte(0x28)
    elseif p.id == 0x061 then
        player.stats.HP_Max                 = p.data:unpack('I',0x01)
        player.stats.MP_Max                 = p.data:unpack('I',0x05)
        player.stats.STR_Base               = p.data:unpack('H',0x11)
        player.stats.DEX_Base               = p.data:unpack('H',0x13)
        player.stats.VIT_Base               = p.data:unpack('H',0x15)
        player.stats.AGI_Base               = p.data:unpack('H',0x17)
        player.stats.INT_Base               = p.data:unpack('H',0x19)
        player.stats.MND_Base               = p.data:unpack('H',0x1B)
        player.stats.CHR_Base               = p.data:unpack('H',0x1D)
        player.stats.STR_Added              = p.data:unpack('H',0x1F)
        player.stats.DEX_Added              = p.data:unpack('H',0x21)
        player.stats.VIT_Added              = p.data:unpack('H',0x23)
        player.stats.AGI_Added              = p.data:unpack('H',0x25)
        player.stats.INT_Added              = p.data:unpack('H',0x27)
        player.stats.MND_Added              = p.data:unpack('H',0x29)
        player.stats.CHR_Added              = p.data:unpack('H',0x2B)
        player.stats.Attack                 = p.data:unpack('H',0x2D)
        player.stats.Defense                = p.data:unpack('H',0x2F)
        player.stats.Fire_Resistance        = p.data:unpack('H',0x31)
        player.stats.Wind_Resistance        = p.data:unpack('H',0x33)
        player.stats.Lightning_Resistance   = p.data:unpack('H',0x35)
        player.stats.Light_Resistance       = p.data:unpack('H',0x37)
        player.stats.Ice_Resistance         = p.data:unpack('H',0x39)
        player.stats.Earth_Resistance       = p.data:unpack('H',0x3B)
        player.stats.Water_Resistance       = p.data:unpack('H',0x3D)
        player.stats.Dark_Resistance        = p.data:unpack('H',0x3F)
    end
end

packet.incoming:register(incoming)
