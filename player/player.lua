local res = require('resources')
local shared = require('shared')
local enumerable = require('enumerable')
local fetch_player = shared.get('player_service', 'player')

local metas = { --meta methods for player tables. these handle indexing for specific table which need addtional index coverage. ex: jobs.Monk, jobs.MNK, jobs[2]
  buffs = {
    __index = function(t,k)
      return setmetatable({}, {
          __index = function(u,l)
            local results = {}
            if l == 'duration' then
              results = t:where(function(v) return v == k end):totable()[1]
              return math.max(rawget(results,'ts')-os.time(),0)
            end
            if l == 'count' then
              return t:count(function(v) return v == k end)
            end
            if type(l) == 'number' then
              results = t:where(function(v) return v == k end):totable()[l]
              return setmetatable({results}, {
                  __index = function(tt,kk)
                    if kk == 'duration' then
                      return math.max(rawget(tt,'ts')-os.time(),0)
                    end
                  end
                })
            end        
            if #t > 0 then
              results = t:where(function(v) return v == k end):totable()[1]
              return rawget(results,l)
            else
              return nil
            end
          end,
          __metatable = false
        })
    end,
    __len = function(t,k)
      local count = 0
      for i in ipairs(t) do
          count = count + 1
      end
      return count
    end,
  },   
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
  job_points = {                                                              
    index = function(t,k)                                                    
      if type(k) == 'string' then                                              
        k = k:lower()                                                          
        local job                                                             
        for _,_job in pairs(res.jobs) do                                               
          if job.english:lower() == k or job.ens:lower() == k then                   
            job = _job                                                          
            break                                                               
          end                                                                   
        end                                                                     
        if job then                                                             
          local tab = {total = 0,current = {}}                                  
          for i=job.id*64,job.id*64-2,2 do                                      
            if res.job_points[i] then                                           
              local val = rawget(t,i)                                           
              tab.current[res.job_points[i].en] = val                           
              tab.total = tab.total + (val>0 and val)                           
            end                                                                 
          end                                                                   
          return tab                                                            
        else                                                                    
          local job_point                                                       
          for _,_job_point in pairs(res.job_points) do                                   
            if _job_point.english:lower() == k or _job_point.ens:lower() == k then   
              _job_point = job_point                                            
              break                                                             
            end                                                                 
          end                                                                   
          if job_point then                                                     
            return rawget(t,job_point.id)                                       
          end                                                                   
        end                                                                     
      end                                                                       
      return rawget(t,k)                                                        
    end},  
  merit_points ={
    index = function(t,k)
      if type(k) == 'string' then
        local job 
        for _,_job in pairs(res.jobs) do
          if job.english:lower() == k or job.ens:lower() == k then
            job = _job
            break
          end
        end
        if job and job.id ~= 0 then
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
        else
          local merit_point
          for _,_merit_point in pairs(res.merit_point) do
            if _merit_point.english:lower() == k or _merit_point.ens:lower() == k then
              merit_point = _merit_point
              break
            end
          end          
          if merit_point then
            return rawget(t,merit_point.id)
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
enumerable.init_type(metas.buffs)
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
      if k == 'buffs' then
        return setmetatable(result,metas['buffs'])
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