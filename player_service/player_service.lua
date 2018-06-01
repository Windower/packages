require('bit')
local pack = require('pack')
local packet = require('packet')
local packets = require('packets')
local shared = require('shared')
local res = require('resources')

player = shared.new('player')

player.env = {
    next = next,
}
  
player.data = {
    linkshell1 = { message = {}, },
    linkshell2 = { message = {}, },
    skills = {},
    models = {},
    job_levels = {},
}

local incoming = {} -- table of incoming packet ids that have an assoiated handler functions
incoming[0x00A] = function(p)   -- Zone Update
  player.data.id                           = p.data:unpack('I',0x01)
  player.data.index                        = p.data:unpack('H',0x05)
  player.data.name                         = p.data:unpack('S16',0x81):gsub('\0','') --REVISIT: Arcon is changing 'z'
  player.data.main_job_id                  = p.data:byte(0xB1)
  player.data.sub_job_id                   = p.data:byte(0xB4)

-- 16 job levels here, but not all of them?
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
      player.data.hp_percent              = p.data:unpack('C',0x1B)
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

incoming.handler = function(p)  -- function that selects id specific handler funcion
  if p.injected then return end

  if incoming[p.id] then 
    incoming[p.id](p)     
  end
end

packet.incoming:register(incoming.handler)

packets.incoming.register(0x01B, function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
    for i = 1, 0x15 do
      data.jobs[i] = p.jobs_levels[i]
    end
end)

packets.incoming.register(0x037, function(p)
    local data = player.data
    data.id = p.id
    data.hp_percent = p.hp_percent
    data.status = p.status
    data.linkshell1.red = p.linkshell1_red
    data.linkshell1.green = p.linkshell1_green
    data.linkshell1.blue = p.linkshell1_blue
    data.pet_index = p.pet_index
end)

packets.incoming.register(0x061, function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
    data.title_id = p.title_id
    data.nation_rank = p.nation_rank
    data.nation_rank_points = p.nation_rank_points
    data.home_point_zone_id = p.home_point_zone_id
    data.nation_id = p.nation_id
    data.superior_level = p.superior_level
    data.item_level = p.item_level + p.main_job_level
    data.exp = p.exp
    data.exp_required = p.exp_required
end)

packets.incoming.register(0x062, function(p)
    local data = player.data
    data.main_job_id = p.main_job_id
    data.main_job_level = p.main_job_level
    data.sub_job_id = p.sub_job_id
    data.sub_job_level = p.sub_job_level
    data.hp_max = p.hp_max
    data.mp_max = p.mp_max
end)

packets.incoming.register(0x062, function(p)
    local data = player.data.skills
    for i = 0x00, 0x30 do
        local skill = data[i]
        local packet = p.combat_skills[i]
        skill.level = packet.level
        skill.capped = packet.capped
    end
    for i = 0x00, 0x0A do
        local skill = data[i]
        local packet = p.combat_skills[i]
        skill.level = packet.level
        skill.rank_id = packet.rank_id
        skill.capped = packet.capped
    end
end)

packets.incoming.register(0x0CC, function(p)
    local ls_number = bit.band(p.flags, 0x40) == 0x40 and 2 or 1
    local data = player.data[('linkshell%u'):format(ls_number)]
    data.name = p.linkshell_name
    data.message.text = p.message
    data.message.player_name = p.player_name
    data.message.timestamp = p.timestamp
    data.message.permissions = p.permissions
end)

packets.incoming.register(0x0DF, function(p)
    local data = player.data
    if data.id ~= p.id then
        return
    end

    data.id = p.id
    data.index = p.index
    data.hp = p.hp
    data.mp = p.mp
    data.tp = p.tp
    data.hp_percent = p.hp_percent
    data.mp_percent = p.mp_percent
    data.main_job.id = p.main_job
    data.main_job.level = p.main_job_level
    data.sub_job.id = p.sub_job
    data.sub_job.level = p.sub_job_level
end)

packets.incoming.register(0x0E2, function(p)
    local data = player.data
    if data.id ~= p.id then
        return
    end

    data.id = p.id
    data.index = p.index
    data.hp = p.hp
    data.mp = p.mp
    data.tp = p.tp
    data.hp_percent = p.hp_percent
    data.mp_percent = p.mp_percent
end)
