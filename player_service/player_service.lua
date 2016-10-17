-- player_service
--[[
player = {
    name='',
    id = -1
    index=-1,
    main_job_id=-1,
    main_job_level=-1,
    sub_job_id=-1,
    sub_job_level=-1,
    status=-1,
    pet_index=-1,
    title_id=-1,
    home_point_zone_id=-1,
    superior_level=-1,
    stats={
        hp_max=1,
        hp_current=1,
        hpp=100,
        mp_max=1,
        mp_current=1,
        mpp=100,
        tp=0,
        str=0, -- Calculated
        str_base=0,
        str_added=0,
        dex=0, -- Calculated
        dex_base=0,
        dex_added=0,
        vit=0, -- Calculated
        vit_base=0,
        vit_added=0,
        agi=0, -- Calculated
        agi_base=0,
        agi_added=0,
        int=0, -- Calculated
        int_base=0,
        int_added=0,
        mnd=0, -- Calculated
        mnd_base=0,
        mnd_added=0,
        chr=0, -- Calculated
        chr_base=0,
        chr_added=0,
        attack=0,
        defense=0,
        fire_resistance=0,
        ice_resistance=0,
        wind_resistance=0,
        earth_resistance=0,
        lightning_resistance=0,
        water_resistance=0,
        light_resistance=0,
        dark_resistance=0,
        },
        
    known_spells = {[1]=true},
    -- Table with a numerical key and a boolean value indicating whether you know each spell
    -- in the resources (Ex. known_spells[1] is true if you know Cure, spell 1)
    
    available_spells = {[1]=true},
    -- Table with a numerical key and a boolean value indicating whether you currently have
    -- access to each spell in the resources (Ex. available_spells[1] is true if you can cast Cure, spell 1)
    
    available_abilities = {[16]=true},
    -- Table with a numerical key and a boolean value indicating whether you currently have
    -- access to each job ability in the resources (Ex. available_abilities[16] is true if you can cast Mighty strikes, Ability 16)
    
    buffs = {
        [1]={
            id=0,
            ts=-1,
            duration=0, -- Calculated
            }
        },
    -- Table keyed to the numbers 1-32 (max 32 buffs in your buff line) with each key having
    -- a table assigned to it that includes the buff ID for the corresponding resource, the
    -- "wears off" timestamp, and the calculated remaining duration of the buff (min 0).
    
    jobs = {
        [1]={
            level=-1,
            capacity_points=-1,
            job_points=-1,
            spent_job_points=-1,
            },
        WAR={
            level=-1,
            capacity_points=-1,
            job_points=-1,
            spent_job_points=-1,
            },
        Warrior={
            level=-1,
            capacity_points=-1,
            job_points=-1,
            spent_job_points=-1,
            },
        ...
        },
    -- This table can be accessed in two ways:
    -- 1) Cheapest is to use job ID
    -- 2) Long or short job name can also be used
    -- The returned table contains information about the job's level, the current number of capacity
    -- points it has, the current number of job points it has, and the number of job points it has spent.
    
    merits = {
        [384]={ -- Berserk Recast Merit points
            level=-1,
            next_cost=-1, --REVISIT: What is this when you're capped?
            },
            
        ['Berserk Recast']={
                level=-1,
                next_cost=-1,
            }
        
        WAR={
            ['Berserk Recast']={
                level=-1,
                next_cost=-1, --REVISIT: What is this when you're capped?
                },
            ['Defender Recast']={
                    ...
                },
                ...
            },
        
        Warrior={
            ['Berserk Recast']={
                level=-1,
                next_cost=-1, --REVISIT: What is this when you're capped?
                },
            ['Defender Recast']={
                    ...
                },
                ...
            },
            
        ...
        
        },
    -- There are three ways to index this table:
    -- 1) The cheapest way is to directly use the merit point ID (Ex. 384).
    -- 2) You can use the string name for the single merit point you're interested in looking at (Ex. "Berserk Recast").
    -- 3) You can use the long or short string name for the job you're interested in to get a table of the job-specific
    --      merit points associated with said job.
    -- Each merit point table has two entries, the current level and the next_cost you have to pay to advance it
    
    job_points = {
        [64]= -1, -- Mighty strikes Effect Job points
        
        ['Mighty strikes Effect']=-1,
        
        WAR={
            total = 0, -- Calculated
            current = {
                ['Mighty strikes Effect']= -1,
                ['Berserk Effect']= -1,
                ...
                },
            },
        
        Warrior={
            total = 0, -- Calculated
            current = {
                ['Mighty strikes Effect']= -1,
                ['Berserk Effect']= -1,
                ...
                },
            },
        ...
        },
    -- There are three ways to index this table:
    -- 1) The cheapest way is to directly use the job point ID (Ex. 64).
    -- 2) You can use the string name for the single merit point you're interested in looking at (Ex. "Berserk Effect").
    -- 3) You can use the long or short string name for the job you're interested in to get a table of the job points associated with said job.
    -- Individual job point entries just have the current level. If you use option #3, those entries are passed
    --  back in a table "current" and you are given an additional parameter "total" which is the total number of job points spent on the job.
    
    linkshell1 = {
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
    },
    linkshell2 = {
    message = {
        ts = -1,
        text = '',
        player_name = '',
        permissions = -1,
        },
    name = '',
    },
    indi = {
        element_id = -1,
        size = -1,
        type = '',
    },
    nation = {
        id = -1,
        rank = -1,
        points = -1,
        name = '', -- Calculated
    },
    unity = {
        id = -1,
        points = -1,
    },
    skills = {
        [1]={ -- Hand-to-Hand
            level=-1,
            capped=false,
            },
        ['Hand-to-Hand']={
            level=-1,
            capped=false,
            },
        [48]={ -- Fishing
            level=-1,
            capped=false,
            rank_id=-1,
            },
        ['Fishing']={
            level=-1,
            capped=false,
            rank_id=-1,
            },
        ...
        }
    -- There are two ways to access this table:
    -- 1) Cheapest is to use the skill ID
    -- 2) You can also use the skill's english name
    -- The returned table includes the level, a boolean indicating whether the skill is capped,
    --  and, for "Synthesis"-type skills, a rank_id.
    }
]]

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
    if type(k) == 'string' and rawget(t,k..'_base') then
        -- So str returns the total str but doesn't need to be continuously adjusted
        return rawget(t,k..'_base')+rawget(t,k..'_added')
    end
    return rawget(t,k)
end
defaults.stats = {
    hp_max=1,
    hp_current=1,
    hpp=100,
    mp_max=1,
    mp_current=1,
    mpp=100,
    tp=0,
    str_base=0,
    str_added=0,
    dex_base=0,
    dex_added=0,
    vit_base=0,
    vit_added=0,
    agi_base=0,
    agi_added=0,
    int_base=0,
    int_added=0,
    mnd_base=0,
    mnd_added=0,
    chr_base=0,
    chr_added=0,
    attack=0,
    defense=0,
    fire_resistance=0,
    ice_resistance=0,
    wind_resistance=0,
    earth_resistance=0,
    lightning_resistance=0,
    water_resistance=0,
    light_resistance=0,
    dark_resistance=0,
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
    defaults.jobs[v] = {
        level=-1,
        capacity_points=-1,
        job_points=-1,
        spent_job_points=-1,}
end
function index_jobs(t,k)
    if type(k) == 'string' then
        print(351, res.jobs)
        print(352, res.jobs:with())
        print(353, res.jobs:with('ens',k),k)
        print(354, res.jobs:with('en',k))
        local job = res.jobs:with('en',k) or res.jobs:with('ens',k)
        if job and job.id ~= 0 then
            return rawget(t,job.id)
        end
    end
    return rawget(t,k)
end
setmetatable(defaults.jobs,{__index=index_jobs})

defaults.merits = {}
-- REVISIT: Need to implement
for _,v in pairs(res_cache.merit_points_keys) do
    defaults.merits[v] = {
            next_cost = -1,
            level = -1,
        }
end
function index_merit_points(t,k)
    if type(k) == 'string' then
        local job = res.jobs:with('en',k) or res.jobs:with('ens',k)
        if job and job.id ~= 0 then
            -- Assemble a table of merit points for that job and return it
            local tab = {}
            for i=job.id*64+320,job.id*64+318,2 do
                if res.merit_points[i] then
                    tab[res.merit_points[i].en] = rawget(t,i)
                end
            end
            for i=job.id*64+1984,job.id*64+1982,2 do
                if res.merit_points[i] then
                    tab[res.merit_points[i].en] = rawget(t,i)
                end
            end
            return tab
        elseif res.merit_points:with('en',k) then
            return rawget(t,res.merit_points:with('en',k).id)
        end
    end
    return rawget(t,k)
end
setmetatable(defaults.merits,{__index=index_merit_points})

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
                if res.job_points[i] then
                    local val = rawget(t,i)
                    tab.current[res.job_points[i].en] = val
                    tab.total = tab.total + (val>0 and val)
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
function index_nations(t,k)
    local nations = {'Bastok','windurst'}
    nations[0] = "San d'Oria"
    if k == 'name' then
        return nations[t.id] or ''
    else
        return rawget(t,k)
    end
end
setmetatable(defaults.nation,{__index=index_nations})

defaults.unity = {
        id = -1,
        points = -1,
    }

defaults.skills = {}
for _,v in pairs(res_cache.skills_keys) do
    defaults.skills[v] = {
        level = -1,
        capped = false,
        }
    if res.skills[v].category == 'Synthesis' then
        defaults.skills[v].rank_id = -1
    end
end
function index_skills(t,k)
    if type(k) == 'string' then
        local skill = res.skills:with('en',k)
        if skill then
            return rawget(t,skill.id)
        end
    end
    return rawget(t,k)
end
setmetatable(defaults.skills,{__index=index_skills})
    
player = share_container()
for i,v in pairs(defaults) do
    player[i] = v
end

function incoming(p)
    if p.injected then return end
    if p.id == 0x00A then
        player.id                           = p.data:unpack('I',0x01)
        player.index                        = p.data:unpack('H',0x05)
        player.name                         = p.data:unpack('z',0x81):gsub('\0','') --REVISIT: Arcon is changing 'z'
        player.main_job_id                  = p.data:byte(0xB1)
        player.sub_job_id                   = p.data:byte(0xB4)
        
        -- 16 job levels here, but not all of them?
        player.stats:notify_changed(false)
        player.stats.str_base               = p.data:unpack('H',0xC9)
        player.stats.dex_base               = p.data:unpack('H',0xCB)
        player.stats.vit_base               = p.data:unpack('H',0xCD)
        player.stats.agi_base               = p.data:unpack('H',0xCF)
        player.stats.int_base               = p.data:unpack('H',0xD1)
        player.stats.mnd_base               = p.data:unpack('H',0xD3)
        player.stats.chr_base               = p.data:unpack('H',0xD5)
        player.stats.str_added              = p.data:unpack('H',0xD7)
        player.stats.dex_added              = p.data:unpack('H',0xD9)
        player.stats.vit_added              = p.data:unpack('H',0xDB)
        player.stats.agi_added              = p.data:unpack('H',0xDD)
        player.stats.int_added              = p.data:unpack('H',0xDF)
        player.stats.mnd_added              = p.data:unpack('H',0xE1)
        player.stats.chr_added              = p.data:unpack('H',0xE3)
        player.stats.hp_max                 = p.data:unpack('I',0xE5)
        player.stats.mp_max                 = p.data:unpack('I',0xE9)
        player.stats:notify_changed(true)
        
    elseif p.id == 0x00D and p.data:unpack('I',1) == player.id then
        -- Should pull in data from this packet, but need to work out the flags precisely
    elseif p.id == 0x01B then
        player.main_job_id                  = p.data:byte(0x05)
        player.main_job_level               = p.data:byte(0x06)
        player.sub_job_level                = p.data:byte(0x07)
        player.sub_job_id                   = p.data:byte(0x08)
        
        player.stats:notify_changed(false)
        player.stats.str_base               = p.data:unpack('H',0x1D)
        player.stats.dex_base               = p.data:unpack('H',0x1F)
        player.stats.vit_base               = p.data:unpack('H',0x21)
        player.stats.agi_base               = p.data:unpack('H',0x23)
        player.stats.int_base               = p.data:unpack('H',0x25)
        player.stats.mnd_base               = p.data:unpack('H',0x27)
        player.stats.chr_base               = p.data:unpack('H',0x29)
        player.stats.hp_max                 = p.data:unpack('I',0x39)
        player.stats.mp_max                 = p.data:unpack('I',0x3D)
        player.stats:notify_changed(true)
        
        player.jobs:notify_changed(false)
        for i=0,res.jobs:len() do
            player.jobs[i].level  = p.data:byte(i+0x45)
        end
        player.jobs:notify_changed(true)
    elseif p.id == 0x037 then
        local bitmask = p.data:sub(0x49,0x50)
        player.buffs:notify_changed(false)
        for i = 1,32 do
            local bitmask_position = 2*((i-1)%4)
            player.buffs[i].id = p.data:byte(i) + 256*math.floor(bitmask:byte(1+math.floor((i-1)/4))%(2^(bitmask_position+2))/(2^bitmask_position))
        end
        player.buffs:notify_changed(true)
        
        player.id                           = p.data:unpack('I',0x21)
        player.stats.hpp                    = p.data:byte(0x27)
        player.status                       = p.data:byte(0x2D)
        
        player.linkshell1:notify_changed(false)
        player.linkshell1.red                = p.data:byte(0x2E)
        player.linkshell1.green              = p.data:byte(0x2F)
        player.linkshell1.blue               = p.data:byte(0x30)
        player.linkshell1:notify_changed(true)
        
        player.pet_index                    = bit.rshift(p.data:unpack('H',0x31),3)
        
        player.indi:notify_changed(false)
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
        player.indi:notify_changed(true)
    elseif p.id == 0x055 then
        -- Add key items?
    elseif p.id == 0x056 then
        -- Add quests/missions?
    elseif p.id == 0x061 then
        player.stats:notify_changed(false)
        player.stats.hp_max                 = p.data:unpack('I',0x01)
        player.stats.mp_max                 = p.data:unpack('I',0x05)
        player.stats.str_base               = p.data:unpack('H',0x11)
        player.stats.dex_base               = p.data:unpack('H',0x13)
        player.stats.vit_base               = p.data:unpack('H',0x15)
        player.stats.agi_base               = p.data:unpack('H',0x17)
        player.stats.int_base               = p.data:unpack('H',0x19)
        player.stats.mnd_base               = p.data:unpack('H',0x1B)
        player.stats.chr_base               = p.data:unpack('H',0x1D)
        player.stats.str_added              = p.data:unpack('H',0x1F)
        player.stats.dex_added              = p.data:unpack('H',0x21)
        player.stats.vit_added              = p.data:unpack('H',0x23)
        player.stats.agi_added              = p.data:unpack('H',0x25)
        player.stats.int_added              = p.data:unpack('H',0x27)
        player.stats.mnd_added              = p.data:unpack('H',0x29)
        player.stats.chr_added              = p.data:unpack('H',0x2B)
        player.stats.attack                 = p.data:unpack('H',0x2D)
        player.stats.defense                = p.data:unpack('H',0x2F)
        player.stats.fire_resistance        = p.data:unpack('H',0x31)
        player.stats.wind_resistance        = p.data:unpack('H',0x33)
        player.stats.lightning_resistance   = p.data:unpack('H',0x35)
        player.stats.light_resistance       = p.data:unpack('H',0x37)
        player.stats.ice_resistance         = p.data:unpack('H',0x39)
        player.stats.earth_resistance       = p.data:unpack('H',0x3B)
        player.stats.water_resistance       = p.data:unpack('H',0x3D)
        player.stats.dark_resistance        = p.data:unpack('H',0x3F)
        player.stats:notify_changed(true)
        
        player.title_id                     = p.data:unpack('H',0x41)
        
        player.nation:notify_changed(false)
        player.nation.rank                  = p.data:unpack('H',0x43)
        player.nation.points                = p.data:unpack('H',0x45) -- REVISIT: Is this correct?
        player.nation:notify_changed(true)
        
        player.home_point_zone_id           = p.data:unpack('H',0x47)
        player.nation.id                    = p.data:byte(0x4D)
        player.superior_level               = p.data:byte(0x4F)
        
        player.unity:notify_changed(false)
        player.unity.id                     = bit.band(p.data:byte(0x55),0x1F)
        player.unity.points                 = math.floor(p.data:byte(0x56)/4) + p.data:byte(0x57)*2^6 + p.data:byte(0x58)*2^14 -- REVISIT: Incorrect
        player.unity:notify_changed(true)
    elseif p.id == 0x062 then
        player.skills:notify_changed(false)
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
        player.skills:notify_changed(true)
    elseif p.id == 0x063 then
        local packet_type = p.data:unpack('H',0x01)
        if packet_type == 5 then
            player.jobs:notify_changed(false)
            for i,v in pairs(res_cache.jobs_keys) do
                player.jobs[v].capacity_points    = p.data:unpack('H',3+v*6)
                player.jobs[v].job_points         = p.data:unpack('H',5+v*6)
                player.jobs[v].spent_job_points   = p.data:unpack('H',7+v*6)
            end
            player.jobs:notify_changed(true)
        elseif packet_type == 9 then
            player.buffs:notify_changed(false)
            for i=1,32 do
                player.buffs[i].id = p.data:unpack('H',3+2*i)
                player.buffs[i].ts = p.data:unpack('I',0x41+4*i)
            end
            player.buffs:notify_changed(true)
        end
    elseif p.id == 0x08C then
        local count = p.data:byte(1)
        player.merits:notify_changed(false)
        for i=1,count do
            local id = p.data:unpack('H',i*4+1)
            player.merits[id].next_cost = p.data:byte(i*4+3)
            player.merits[id].level = p.data:byte(i*4+4)
        end
        player.merits:notify_changed(true)
    elseif p.id == 0x08D then
        local i = 1
        player.job_points:notify_changed(false)
        while p.data[i] do
            local id = p.data[i]:unpack('H',i)
            player.job_points[id] = bit.rshift(p.data:byte(i+3),2)
            i = i + 4
        end
        player.job_points:notify_changed(true)
    elseif p.id == 0x0AA then
        -- Spell List
    elseif p.id == 0x0AC then
        -- Ability List
    elseif p.id == 0x0AE then
        -- Mount List
    elseif p.id == 0x0CC then
        local linkshell_number = (bit.band(p.data:byte(2),0x40) == 0x40 and 2) or 1
        player['linkshell'..linkshell_number]:notify_changed(false)
        
        player['linkshell'..linkshell_number].message.text = p.data:unpack('z',5):gsub('\0','') --REVISIT: Arcon is changing 'z'
        player['linkshell'..linkshell_number].message.player_name = p.data:unpack('z',0x89):gsub('\0','') --REVISIT: Arcon is changing 'z'
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
        
        player['linkshell'..linkshell_number]:notify_changed(true)
    elseif p.id == 0x0DF then
        if player.id == p.data:unpack('I',0x01) then
        
            player.stats:notify_changed(false)
            player.stats.hp_current = p.data:unpack('I',0x05)
            player.stats.mp_current = p.data:unpack('I',0x09)
            player.stats.tp = p.data:unpack('I',0x0D)
            player.stats.hpp = p.data:byte(0x13)
            player.stats.mpp = p.data:byte(0x14)
            player.stats:notify_changed(true)
            
            player.index = p.data:unpack('H',0x11)
            player.main_job_id = p.data:byte(0x1D)
            player.main_job_level = p.data:byte(0x1E)
            player.sub_job_id = p.data:byte(0x1F)
            player.sub_job_level = p.data:byte(0x20)
        end
    elseif p.id == 0x0E2 then
        if player.id == p.data:unpack('I',0x01) then
        
            player.stats:notify_changed(false)
            player.stats.hp_current = p.data:unpack('I',0x05)
            player.stats.mp_current = p.data:unpack('I',0x09)
            player.stats.tp = p.data:unpack('I',0x0D)
            player.stats.hpp = p.data:byte(0x1A)
            player.stats.mpp = p.data:byte(0x1B)
            player.stats:notify_changed(true)
            
            player.index = p.data:unpack('H',0x15)
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