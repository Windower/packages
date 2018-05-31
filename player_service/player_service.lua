require('bit')
local pack   = require('pack')
local packet = require('packet')
local shared = require('shared')
local res    = require('resources')

player = shared.new('player')

player.env = {
  next = next,
}
  local function keys(t)
    local keys={}
    local i=0
    for k,v in pairs(t) do
      i=i+1
      keys[i]=k
    end
    return keys
  end

  local res_keys = {
    jobs_keys = keys(res.jobs),
    skills_keys = keys(res.skills),
  }  
  
defaults = {
  id = -1,
  index = -1,
  main_job_id = 0,
  main_job_level = -1,
  sub_job_id = -1,
  sub_job_level = -1,
  status = -1,
  pet_index = -1,
  name = '',
  title_id = -1,
  home_point_zone_id = -1,
  superior_level = -1,
  experience_points = -1,
  required_experience_points = -1,
  jobs = {},
  hp_max=-1,
  hp=-1,
  hpp=-1,
  mp_max=-1,
  mp=-1,
  mpp=-1,
  tp=-1,
  attack=-1,
  defense=-1,

  stats = {
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

    fire_resistance=0,
    ice_resistance=0,
    wind_resistance=0,
    earth_resistance=0,
    lightning_resistance=0,
    water_resistance=0,
    light_resistance=0,
    dark_resistance=0,
  },


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


  nation = {
    id = -1,
    rank = -1,
    points = -1,
  },


  skills = {},

}
do
  for _,v in pairs(res_keys.skills_keys) do
    defaults.skills[v] = {
      level = -1,
      capped = false,
    }
    if res.skills[v].category == 'Synthesis' then
      defaults.skills[v].rank_id = -1
    end
  end
  defaults.jobs[defaults.main_job_id] = {
    level = -1,
  }
  for _,v in pairs(res_keys.jobs_keys) do
    defaults.jobs[v] = {
      level = -1,
    }
  end
  

end
player.data = {}
for i,v in pairs(defaults) do
  player.data[i] = v
end

local incoming = {} -- table of incoming packet ids that have an assoiated handler functions
incoming[0x00A] = function(p)   -- Zone Update
  player.data.id                           = p.data:unpack('I',0x01)
  player.data.index                        = p.data:unpack('H',0x05)
  player.data.name                         = p.data:unpack('S16',0x81):gsub('\0','') --REVISIT: Arcon is changing 'z'
  player.data.main_job_id                  = p.data:byte(0xB1)
  player.data.sub_job_id                   = p.data:byte(0xB4)

-- 16 job levels here, but not all of them?
  player.data.stats.str_base               = p.data:unpack('H',0xC9)
  player.data.stats.dex_base               = p.data:unpack('H',0xCB)
  player.data.stats.vit_base               = p.data:unpack('H',0xCD)
  player.data.stats.agi_base               = p.data:unpack('H',0xCF)
  player.data.stats.int_base               = p.data:unpack('H',0xD1)
  player.data.stats.mnd_base               = p.data:unpack('H',0xD3)
  player.data.stats.chr_base               = p.data:unpack('H',0xD5)
  player.data.stats.str_added              = p.data:unpack('H',0xD7)
  player.data.stats.dex_added              = p.data:unpack('H',0xD9)
  player.data.stats.vit_added              = p.data:unpack('H',0xDB)
  player.data.stats.agi_added              = p.data:unpack('H',0xDD)
  player.data.stats.int_added              = p.data:unpack('H',0xDF)
  player.data.stats.mnd_added              = p.data:unpack('H',0xE1)
  player.data.stats.chr_added              = p.data:unpack('H',0xE3)
  player.data.hp_max                       = p.data:unpack('I',0xE5)
  player.data.mp_max                       = p.data:unpack('I',0xE9)
end 
incoming[0x00D] = function(p)   -- PC entity update packet
  local id = p.data:unpack('I',0x01)
  if player.data.id ~= -1 and player.data.id == id then
    local pc_update = {}
    pc_update[0] = function(p) --Handle pc location  update bit 0x0A
      player.data.position.heading         = p.data:unpack('C',0x08)
      player.data.position.x               = p.data:unpack('f',0x09)
      player.data.position.z               = p.data:unpack('f',0x0D)
      player.data.position.y               = p.data:unpack('f',0x11)
      player.data.position.walk_counter    = p.data:unpack('I',0x15)  

      player.data.target_index             = p.data:unpack('I',0x17)
      player.data.movement_speed           = p.data:unpack('C',0x19)
      player.data.animation_speed          = p.data:unpack('C',0x1A)
    end
    pc_update[1] = function(p) --Not Used

    end
    pc_update[2] = function(p) --Handle pc status    update bit 0x2A
      player.data.hpp                     = p.data:unpack('C',0x1B)
      player.data.status                  = p.data:unpack('C',0x1C)
      player.data.flag                    = p.data:unpack('I',0x1D)
      player.data.face_flag               = p.data:unpack('C',0x40)  
      player.data.linkshell1.red          = p.data:unpack('C',0x21)
      player.data.linkshell1.green        = p.data:unpack('C',0x22)
      player.data.linkshell1.blue         = p.data:unpack('C',0x23)

    end
    pc_update[3] = function(p) --Handle pc name      update bit 0x3A
      player.data.name                    = p.data:unpack('z',0x57):gsub('\0','')
    end
    pc_update[4] = function(p) --Handle pc model     update bit 0x4A
      player.data.face                    = p.data:unpack('C',0x45)
      player.data.race                    = p.data:unpack('C',0x46)
      player.data.equipment = { --visible equipment
        head                          = p.data:unpack('H',0x47),
        body                          = p.data:unpack('H',0x49),
        hands                         = p.data:unpack('H',0x4B),
        legs                          = p.data:unpack('H',0x4D),
        feet                          = p.data:unpack('H',0x4F),
        main                          = p.data:unpack('H',0x51),
        sub                           = p.data:unpack('H',0x53),
        ranged                        = p.data:unpack('H',0x55),
      }
    end
    pc_update[5] = function(p)    --Handle pc out of range update bit 0x5A
    end
    local updates = {p.data:unpack('q8', 0x0A)}
    for k,v in pairs(updates) do
      if v and pc_update[k] then
        pc_update[k](p)
      end
    end
  end  
end 
incoming[0x01B] = function(p)   -- Job Info
  player.data.main_job_id                  = p.data:byte(0x05)
  player.data.main_job_level               = p.data:byte(0x06)
  player.data.sub_job_level                = p.data:byte(0x07)
  player.data.sub_job_id                   = p.data:byte(0x08)

  player.data.hp_max                       = p.data:unpack('I',0x39)
  player.data.mp_max                       = p.data:unpack('I',0x3D)

  player.data.stats.str_base               = p.data:unpack('H',0x1D)
  player.data.stats.dex_base               = p.data:unpack('H',0x1F)
  player.data.stats.vit_base               = p.data:unpack('H',0x21)
  player.data.stats.agi_base               = p.data:unpack('H',0x23)
  player.data.stats.int_base               = p.data:unpack('H',0x25)
  player.data.stats.mnd_base               = p.data:unpack('H',0x27)
  player.data.stats.chr_base               = p.data:unpack('H',0x29)

  for i=0,#res.jobs-1 do
    player.data.jobs[i].level  = p.data:byte(i+0x45)
  end
end 
incoming[0x037] = function(p)   -- Player Update
  player.data.id                            = p.data:unpack('I',0x21)
  player.data.hpp                           = p.data:byte(0x27)
  player.data.status                        = p.data:byte(0x2D)

  player.data.linkshell1.red                = p.data:byte(0x2E)
  player.data.linkshell1.green              = p.data:byte(0x2F)
  player.data.linkshell1.blue               = p.data:byte(0x30)

  player.data.pet_index                    = bit.rshift(p.data:unpack('H',0x31),3)
end 
incoming[0x061] = function(p)   -- Char Stats
  player.data.main_job_id                  = p.data:byte(0x09)
  player.data.main_job_level               = p.data:byte(0x0A)
  player.data.sub_job_id                   = p.data:byte(0x0B)
  player.data.sub_job_level                = p.data:byte(0x0C)

  player.data.hp_max                       = p.data:unpack('I',0x01)
  player.data.mp_max                       = p.data:unpack('I',0x05)
  player.data.stats.str_base               = p.data:unpack('H',0x11)
  player.data.stats.dex_base               = p.data:unpack('H',0x13)
  player.data.stats.vit_base               = p.data:unpack('H',0x15)
  player.data.stats.agi_base               = p.data:unpack('H',0x17)
  player.data.stats.int_base               = p.data:unpack('H',0x19)
  player.data.stats.mnd_base               = p.data:unpack('H',0x1B)
  player.data.stats.chr_base               = p.data:unpack('H',0x1D)
  player.data.stats.str_added              = p.data:unpack('H',0x1F)
  player.data.stats.dex_added              = p.data:unpack('H',0x21)
  player.data.stats.vit_added              = p.data:unpack('H',0x23)
  player.data.stats.agi_added              = p.data:unpack('H',0x25)
  player.data.stats.int_added              = p.data:unpack('H',0x27)
  player.data.stats.mnd_added              = p.data:unpack('H',0x29)
  player.data.stats.chr_added              = p.data:unpack('H',0x2B)
  player.data.attack                       = p.data:unpack('H',0x2D)
  player.data.defense                      = p.data:unpack('H',0x2F)
  player.data.stats.fire_resistance        = p.data:unpack('H',0x31)
  player.data.stats.wind_resistance        = p.data:unpack('H',0x33)
  player.data.stats.lightning_resistance   = p.data:unpack('H',0x35)
  player.data.stats.light_resistance       = p.data:unpack('H',0x37)
  player.data.stats.ice_resistance         = p.data:unpack('H',0x39)
  player.data.stats.earth_resistance       = p.data:unpack('H',0x3B)
  player.data.stats.water_resistance       = p.data:unpack('H',0x3D)
  player.data.stats.dark_resistance        = p.data:unpack('H',0x3F)

  player.data.title_id                     = p.data:unpack('H',0x41)

  player.data.nation.rank                  = p.data:unpack('H',0x43)
  player.data.nation.points                = p.data:unpack('H',0x45) -- REVISIT: Is this correct?

  player.data.home_point_zone_id           = p.data:unpack('H',0x47)
  player.data.nation.id                    = p.data:byte(0x4D)

  player.data.superior_level               = p.data:byte(0x4F)
  player.data.item_level                   = p.data:byte(0x52)+player.data.main_job_level--54)

  player.data.experience_points            = p.data:unpack('H',0x0D)
  player.data.required_experience_points   = p.data:unpack('H',0x0F)
end 
incoming[0x062] = function(p)   -- Skill Update
  for _,v in pairs(res_keys.skills_keys) do
    if res.skills[v].category == 'Synthesis' then 
      player.data.skills[res.skills[v].id].level = bit.rshift(bit.band(p.data:unpack('H',0x7D + 2*v),32736),5)
      player.data.skills[res.skills[v].id].rank_id = bit.band(p.data:unpack('H',0x7D + 2*v),31)
      player.data.skills[res.skills[v].id].capped  = bit.band(p.data:unpack('H',0x7D + 2*v),32768) > 0
    else
      player.data.skills[res.skills[v].id].level = bit.band(p.data:unpack('H',0x7D + 2*v),32767)
      player.data.skills[res.skills[v].id].capped  = bit.band(p.data:unpack('H',0x7D + 2*v),32768) > 0
    end
  end
end 

incoming[0x0CC] = function(p)   -- Linkshell Message
  local linkshell_number = (bit.band(p.data:byte(2),0x40) == 0x40 and 2) or 1
  player.data['linkshell'..linkshell_number].message.text = p.data:unpack('z',5):gsub('\0','') --REVISIT: Arcon is changing 'z'
  player.data['linkshell'..linkshell_number].message.player_name = p.data:unpack('z',0x89):gsub('\0','') --REVISIT: Arcon is changing 'z'
  player.data['linkshell'..linkshell_number].message.ts = p.data:unpack('I',0x85)
  player.data['linkshell'..linkshell_number].message.permissions = p.data:unpack('I',0x95)

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
  player.data['linkshell'..linkshell_number].name = name

end 
incoming[0x0DF] = function(p)   -- Char Update
  if player.data.id == p.data:unpack('I',0x01) then

    player.data.hp              = p.data:unpack('I',0x05)
    player.data.mp              = p.data:unpack('I',0x09)
    player.data.tp              = p.data:unpack('I',0x0D)
    player.data.hpp             = p.data:byte(0x13)
    player.data.mpp             = p.data:byte(0x14)

    player.data.index           = p.data:unpack('H',0x11)
    player.data.main_job_id     = p.data:byte(0x1D)
    player.data.main_job_level  = p.data:byte(0x1E)
    player.data.sub_job_id      = p.data:byte(0x1F)
    player.data.sub_job_level   = p.data:byte(0x20)
  end
end 
incoming[0x0E2] = function(p)   -- Char Info
  if player.data.id == p.data:unpack('I',0x01) then

    player.data.hp              = p.data:unpack('I',0x05)
    player.data.mp              = p.data:unpack('I',0x09)
    player.data.tp              = p.data:unpack('I',0x0D)
    player.data.hpp             = p.data:byte(0x1A)
    player.data.mpp             = p.data:byte(0x1B)

    player.data.index = p.data:unpack('H',0x15)
  end
end 

incoming.handler = function(p)  -- function that selects id specific handler funcion
  if p.injected then return end

  if incoming[p.id] then 
    incoming[p.id](p)     
  end
end

packet.incoming:register(incoming.handler)