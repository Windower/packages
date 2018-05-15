local res = require('resources')
local shared = require('shared')
local fetch_player = shared.get('player_service', 'player')

local metas = { --meta methods for player tables. these handle indexing for specific table which need addtional index coverage. ex: jobs.Monk, jobs.MNK, jobs[2]
  
  jobs = {                                                      
    index = function(t,k)                                       
      if type(k) == 'string' then                               
        k = k:lower()     
        for _,job in pairs(res.jobs) do            
          if job.english:lower() == k or job.ens:lower() == k then               
            return rawget(t,job.id)                             
          end                                                   
        end                                                     
      end                                                       
      return rawget(t,k)                                        
    end},
  nations = {
    index = function(t,k)
      local nations = {'Bastok','windurst'}
      nations[0] = "San d'Oria"
      if k == 'name' then
        return nations[t.id] or ''
      else
        return rawget(t,k)
      end
    end},
  skills = {
    index = function(t,k)
      if type(k) == 'string' then
        k = k:lower()
        for _,skill in pairs(res.skills) do
          if skill.english:lower() == k then
            return rawget(t,skill.id)        
          end
        end
      end
      return rawget(t,k)
    end},
  stats = {
    index = function(t, k)
      if type(k) == 'string' and rawget(t,k..'_base') then
        return rawget(t,k..'_base')+rawget(t,k..'_added')
      end
      return rawget(t,k)
    end},
}

local get_player_pairs = function(data, key)
  return {next(data, key)}
end

local get_player_value = function(data, key)
  if data[key] ~= nil then
    return data[key]
  else 
    return nil
  end
end

local player = setmetatable({}, {
    __index = function(t,k)
      local ok, result = fetch_player(get_player_value, k)
      if not ok then
        error(result)
      end
      if type(result) == 'table' then
        return setmetatable({},{
            __index = function(_,l)               
              if metas[k] then
                return metas[k].index(result,l)
              else
                return result[l]
              end
            end,
            __newindex = function() error('This value is read-only.') end,
            __pairs =function(t) 
              return function(t, k) return next(result, k) end
            end,
            __metatable = false
          })
      else 
        return result
      end
    end,
    __newindex = function() error('This value is read-only.') end,

    __pairs = function(t)
      return function(t, k)
        local ok, result = fetch_player(get_player_pairs, k)
        if not ok then
          error(result)              
        end
        return unpack(result)
      end, t, nil
    end,

    __metatable = false

  })
return player