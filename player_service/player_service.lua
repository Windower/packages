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
    skills_keys = res.skills:keys(),
    merit_points_keys = res.merit_points:keys(),
    job_points_keys = res.job_points:keys(),
    }

defaults = {}

defaults.id = -1
defaults.index = -1
defaults.main_job_id = -1
defaults.main_job_level = -1
defaults.sub_job_id = -1
defaults.sub_job_level = -1
defaults.status = -1
defaults.pet_index = -1
defaults.name = ''
defaults.title_id = -1
defaults.home_point_zone_id = -1
defaults.superior_level = -1

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
    defaults.buffs[i] = setmetatable({id=0,ts=-1},{duration=buff_duration})
end

defaults.jobs = {}
for _,v in ipairs(res_cache.jobs_keys) do
    defaults.jobs[res.jobs[v].ens] = {
        level=-1,
        capacity_points=-1,
        job_points=-1,
        spent_job_points=-1,}
end

defaults.merits = {}
-- Need to implement
for _,v in pairs(res_cache.merit_points_keys) do
    defaults.merits[v] = {
            next_cost = -1,
            level = -1,
        }
end

defaults.job_points = {current=-1}
for _,v in pairs(res_cache.job_points_keys) do
    defaults.job_points[v] = -1
end
function index_job_points(t,k)
    if type(k) == 'string' then
        local job = res.jobs:with('en',k) or res.jobs:with('ens',k)
        if job then
            -- Assemble a table of job points for that job and return it
            local tab = {total = 0,current = {}}
            for i=job.id*64,job.id*64-2,2 do
                if res.job_points[i] and res.job_points[i] >= 0 then
                    tab.current[res.job_points[i].en] = rawget(t,i)
                    tab.total = tab.total + tab[res.job_points[i].en]
                end
            end
            return tab
        elseif res.job_points:with('en',k) then
            return rawget(t,res.job_points:with('en',k).id)
        end
    end
    return rawget(t,k)
end
setmetatable(defaults.job_points,{__index=index_job_points})

defaults.linkshell1 = {
    red = -1,
    green = -1,
    blue = -1,
    message = {
        ts = -1,
        text = '',
        player_name = '',
        permissions = -1,
        },
    name = '',
    }

defaults.linkshell2 = {
    message = {
        ts = -1,
        text = '',
        player_name = '',
        permissions = -1,
        },
    name = '',
    }

defaults.indi = {
        element_id = -1,
        size = -1,
        type = '',
    }

defaults.nation = {
        id = -1,
        rank = -1,
        points = -1,
    }
setmetatable(defaults.nation,{__index=function(t,k)
    local nations = {'Bastok','Windurst'}
    nations[0] = "San d'Oria"
    if k == 'name' then
        return nations[t.id] or 'None'
    else
        return rawget(t,k)
    end
end})

defaults.unity = {
        id = -1,
        points = -1,
    }

defaults.skills = {}
for i,v in pairs(res_cache.skills_keys) do
    local skill = res.skills[v].en
    defaults.skills[skill] = {
        level = -1,
        capped = false,
        }
    if res.skills[v].category == 'Synthesis' then
        defaults.skills[skill].rank_id = -1
    end
end
    
player = share_container()
for i,v in pairs(defaults) do
    player[i] = v
end

function incoming(p)
    if p.injected then return end
    if p.id == 0x00A then
        player.id                           = p.data:unpack('I',0x01)
        player.index                        = p.data:unpack('H',0x05)
        player.name                         = p.data:unpack('z',0x81)
        player.main_job_id                  = p.data:byte(0xB1)
        player.sub_job_id                   = p.data:byte(0xB4)
        -- 16 job levels here, but not all of them?
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
        player.stats.HP_Max                 = p.data:unpack('I',0xE5)
        player.stats.MP_Max                 = p.data:unpack('I',0xE9)
    elseif p.id == 0x00D and p.data:unpack('I',1) == player.id then
        -- Should pull in data from this packet, but need to work out the flags precisely
    elseif p.id == 0x01B then
        player.main_job_id                  = p.data:byte(0x05)
        player.main_job_level               = p.data:byte(0x06)
        player.sub_job_level                = p.data:byte(0x07)
        player.sub_job_id                   = p.data:byte(0x08)
        player.stats.STR_Base               = p.data:unpack('H',0x1D)
        player.stats.DEX_Base               = p.data:unpack('H',0x1F)
        player.stats.VIT_Base               = p.data:unpack('H',0x21)
        player.stats.AGI_Base               = p.data:unpack('H',0x23)
        player.stats.INT_Base               = p.data:unpack('H',0x25)
        player.stats.MND_Base               = p.data:unpack('H',0x27)
        player.stats.CHR_Base               = p.data:unpack('H',0x29)
        player.stats.HP_Max                 = p.data:unpack('I',0x39)
        player.stats.MP_Max                 = p.data:unpack('I',0x3D)
        
        for i=0,res.jobs:len() do
            player.jobs[res.jobs[i].ens].level  = p.data:byte(i+0x45)
        end
    elseif p.id == 0x037 then
        local bitmask = p.data:sub(0x49,0x50)
        for i = 1,32 do
            local bitmask_position = 2*((i-1)%4)
            player.buffs[i].id = p.data:byte(i) + 256*math.floor(bitmask:byte(1+math.floor((i-1)/4))%(2^(bitmask_position+2))/(2^bitmask_position))
        end
        player.id                           = p.data:unpack('I',0x21)
        player.stats.HPP                    = p.data:byte(0x27)
        player.status                       = p.data:byte(0x2D)
        player.linkshell1.red                = p.data:byte(0x2E)
        player.linkshell1.green              = p.data:byte(0x2F)
        player.linkshell1.blue               = p.data:byte(0x30)
        player.pet_index                    = bit.rshift(p.data:unpack('H',0x31),3)
        local indi_byte                     = p.data:byte(0x56)
        if indi_byte%128/64 == 0 then
            player.indi.element_id = default.indi.element_id
            player.indi.type = default.indi.type
            player.indi.size = default.indi.size
        else
            player.indi.element_id = indi_byte%8
            player.indi.size = math.floor((indi_byte%64)/16) + 1 -- Size range of 1~4
            player.indi.type = ((indi_byte%16)/8 >= 1 and 'Debuff') or 'Buff'
        end
    elseif p.id == 0x055 then
        -- Add key items?
    elseif p.id == 0x056 then
        -- Add quests/missions?
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
        player.title_id                     = p.data:unpack('H',0x41)
        player.nation.rank                  = p.data:unpack('H',0x43)
        player.nation.points                = p.data:unpack('H',0x45) -- REVISIT: Is this correct?
        player.home_point_zone_id           = p.data:unpack('H',0x47)
        player.nation.id                    = p.data:byte(0x4D)
        player.superior_level               = p.data:byte(0x4F)
        player.unity.id                     = bit.band(p.data:byte(0x55),0x1F)
        player.unity.points                 = math.floor(p.data:byte(0x56)/4) + p.data:byte(0x57)*2^6 + p.data:byte(0x58)*2^14 -- REVISIT: Incorrect
    elseif p.id == 0x062 then
        for _,v in pairs(res_cache.skills_keys) do
            if res.skills[v].category == 'Synthesis' then
                player.skills[res.skills[v].en].level = bit.rshift(bit.band(p.data:unpack('H',0x7D + 2*v),32736),5)
                player.skills[res.skills[v].en].rank_id = bit.band(p.data:unpack('H',0x7D + 2*v),31)
                player.skills[res.skills[v].en].capped  = bit.band(p.data:unpack('H',0x7D + 2*v),32768) > 0
            else
                player.skills[res.skills[v].en].level = bit.band(p.data:unpack('H',0x7D + 2*v),32767)
                player.skills[res.skills[v].en].capped  = bit.band(p.data:unpack('H',0x7D + 2*v),32768) > 0
            end
        end
    elseif p.id == 0x063 then
        local packet_type = p.data:unpack('H',0x01)
        if packet_type == 5 then
            for i,v in pairs(res_cache.jobs_keys) do
                player.jobs[res.jobs[v].ens].capacity_points    = p.data:unpack('H',3+v*6)
                player.jobs[res.jobs[v].ens].job_points         = p.data:unpack('H',5+v*6)
                player.jobs[res.jobs[v].ens].spent_job_points   = p.data:unpack('H',7+v*6)
            end
        elseif packet_type == 9 then
            for i=1,32 do
                player.buffs[i].id = p.data:unpack('H',3+2*i)
                player.buffs[i].ts = p.data:unpack('I',0x41+4*i)
            end
        end
    elseif p.id == 0x08C then
        local count = p.data:byte(1)
        for i=1,count do
            local id = p.data:unpack('H',i*4+1)
            player.merits[id].next_cost = p.data:byte(i*4+3)
            player.merits[id].level = p.data:byte(i*4+4)
        end
    elseif p.id == 0x08D then
        local i = 1
        while p.data[i] do
            local id = p.data[i]:unpack('H',i)
            player.job_points[id] = bit.rshift(p.data:byte(i+3),2)
            i = i + 4
        end
    elseif p.id == 0x0AA then
        -- Spell List
    elseif p.id == 0x0AC then
        -- Ability List
    elseif p.id == 0x0AE then
        -- Mount List
    elseif p.id == 0x0CC then
        local linkshell_number = (bit.band(p.data:byte(2),0x40) == 0x40 and 2) or 1
        player['linkshell'..linkshell_number].message.text = p.data:unpack('z',5)
        player['linkshell'..linkshell_number].message.player_name = p.data:unpack('z',0x89)
        player['linkshell'..linkshell_number].message.ts = p.data:unpack('I',0x85)
        player['linkshell'..linkshell_number].message.permissions = p.data:unpack('I',0x95)
        
        local name = ''
        local ls_decode = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
        local field = p.data:sub(0x9D,0xAC)
        for i=1,20 do
            local bit_offset = (i-1)*6
            local byte_offset = math.floor(bit_offset/8)+1
            local short = bit.lshift(field:byte(byte_offset),8) + field:byte(byte_offset+1)
            local char_val = bit.band(bit.rshift(short,10-bit_offset%8),0x3F)
            if char_val ~= 0 then
                name = name..ls_decode:sub(char_val,char_val)
            end
        end
        player['linkshell'..linkshell_number].name = name
    elseif p.id == 0x0DF then
        if player.id == p.data:unpack('I',0x01) then
            player.stats.HP_Current = p.data:unpack('I',0x05)
            player.stats.MP_Current = p.data:unpack('I',0x09)
            player.stats.TP = p.data:unpack('I',0x0D)
            player.index = p.data:unpack('H',0x11)
            player.HPP = p.data:byte(0x13)
            player.MPP = p.data:byte(0x14)
            player.main_job_id = p.data:byte(0x1D)
            player.main_job_level = p.data:byte(0x1E)
            player.sub_job_id = p.data:byte(0x1F)
            player.sub_job_level = p.data:byte(0x20)
        end
    elseif p.id == 0x0E2 then
        if player.id == p.data:unpack('I',0x01) then
            player.stats.HP_Current = p.data:unpack('I',0x05)
            player.stats.MP_Current = p.data:unpack('I',0x09)
            player.stats.TP = p.data:unpack('I',0x0D)
            player.index = p.data:unpack('H',0x15)
            player.HPP = p.data:byte(0x1A)
            player.MPP = p.data:byte(0x1B)
            --REVISIT: Is name always in this packet?
        end
    elseif p.id == 0x110 then
        -- Sparks info?
    elseif p.id == 0x112 then
        -- ROE Quest Log?
    elseif p.id == 0x113 then
        -- Currencies
    elseif p.id == 0x118 then
        -- Currencies 2
    elseif p.id == 0x119 then
        -- Add ability recast timers
    end
    --REVISIT: Add Bazaar info?
end

packet.incoming:register(incoming)