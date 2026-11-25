-- Declarative DiceBear timelines. Pure Lua sampling plus optional SVG CSS output.
local util = require('love_dicebear.util')
local M = {}
local order = {'translateX', 'translateY', 'rotate', 'scaleX', 'scaleY', 'opacity'}
local easings = {ease = {.25,.1,.25,1}, easeIn = {.42,0,1,1}, easeOut = {0,0,.58,1}, easeInOut = {.42,0,.58,1}}

local nameCache = setmetatable({}, {__mode='k'})
function M.names(style)
  if nameCache[style] then return nameCache[style] end
  local names = {}
  local function visit(value)
    if type(value) ~= 'table' then return end
    for _, block in ipairs(value.animations or {}) do names[block.name] = true end
    for key, child in pairs(value) do if key ~= 'animations' then visit(child) end end
  end
  visit(style)
  nameCache[style] = util.keys(names)
  return nameCache[style]
end

function M.playing(element, options)
  local result = {}
  for _, block in ipairs(element.animations or {}) do
    local enabled = options[block.name .. 'Animation']
    if enabled == nil then enabled = options.animation end
    if enabled then result[#result + 1] = block end
  end
  return result
end

local function easing(value, t)
  if value == 'hold' then return t < 1 and 0 or 1 end
  local points = type(value) == 'table' and value or easings[value]
  if not points then return t end
  local function bezier(a, b, x) return 3*(1-x)^2*x*a + 3*(1-x)*x*x*b + x^3 end
  local lo, hi = 0, 1
  for _ = 1, 30 do
    local mid = (lo + hi)/2
    if bezier(points[1], points[3], mid) < t then lo = mid else hi = mid end
  end
  return bezier(points[2], points[4], (lo+hi)/2)
end
M.easing = easing

function M.sample(track, seconds)
  local block = track.block
  local elapsed = (seconds - track.delay) / track.duration
  local iterations = block.iterations or 'infinite'
  local fill = block.fill or 'none'
  if elapsed < 0 then
    if fill ~= 'backwards' and fill ~= 'both' then return track.rest end
    elapsed = 0
  end
  local ended = iterations ~= 'infinite' and elapsed >= iterations
  if ended then
    if fill ~= 'forwards' and fill ~= 'both' then return track.rest end
    elapsed = iterations
  end
  local cycle = math.floor(elapsed)
  local phase = elapsed - cycle
  if ended and phase == 0 then cycle, phase = math.max(0, cycle-1), 1 end
  local direction = block.direction or 'normal'
  if direction == 'reverse' or (direction == 'alternate' and cycle % 2 == 1)
      or (direction == 'alternateReverse' and cycle % 2 == 0) then phase = 1-phase end
  local frames = track.frames
  local at = phase * 100
  if at <= frames[1].at then return frames[1].value end
  for i = 2, #frames do
    local left, right = frames[i-1], frames[i]
    if at <= right.at then
      local t = (at-left.at)/(right.at-left.at)
      return left.value + (right.value-left.value)*easing(left.easing or block.easing, t)
    end
  end
  return frames[#frames].value
end

local function cssEasing(value)
  if type(value) == 'table' then return 'cubic-bezier(' .. table.concat(value, ',') .. ')' end
  return ({easeIn='ease-in',easeOut='ease-out',easeInOut='ease-in-out',hold='step-end'})[value] or value or 'linear'
end
local function declaration(kind, value)
  value = util.number(value)
  if kind == 'opacity' then return 'opacity:' .. value end
  local unit = kind == 'rotate' and 'deg' or (kind:sub(1,9) == 'translate' and 'px' or '')
  return 'transform:' .. kind .. '(' .. value .. unit .. ')'
end

function M.context(options, prefix, native)
  local context = {tracks = {}, css = {}, native = native}
  function context:wrap(markup, element, blocks)
    if markup == '' then return markup end
    local tracks = {}
    for _, block in ipairs(blocks) do
      local speed = options[block.name .. 'AnimationSpeed'] or options.animationSpeed or 1
      local delay = options[block.name .. 'AnimationDelay'] or options.animationDelay or 0
      for _, kind in ipairs(order) do
        local data = block.tracks[kind]
        if data then
          local id = 'ldb-anim-' .. prefix .. '-' .. (#self.tracks+1)
          local rest = kind:sub(1,5) == 'scale' and 1 or 0
          if kind == 'opacity' then
            rest = 1
            for _, pair in ipairs(element.attributes or {}) do
              if pair[1] == 'opacity' then rest = tonumber(pair[2]) end
            end
          end
          local track = {id=id, kind=kind, block=block, frames=data.keyframes,
            duration=block.duration/speed, delay=(block.delay or 0)/speed+delay, rest=rest}
          self.tracks[#self.tracks+1], tracks[#tracks+1] = track, track
          if not self.native then
            local frames = {}
            local list = util.copy(data.keyframes)
            if list[1].at > 0 then table.insert(list, 1, {at=0,value=list[1].value}) end
            if list[#list].at < 100 then list[#list+1] = {at=100,value=list[#list].value} end
            for _, frame in ipairs(list) do
              frames[#frames+1] = util.number(frame.at) .. '%{' .. declaration(kind,frame.value)
                .. ';animation-timing-function:' .. cssEasing(frame.easing or block.easing) .. '}'
            end
            local origin = block.origin or {x=50,y=50}
            local direction = block.direction == 'alternateReverse' and 'alternate-reverse' or block.direction or 'normal'
            self.css[#self.css+1] = '@keyframes '..id..'{'..table.concat(frames)..'}#'..id
              .. '{transform-box:fill-box;transform-origin:'..util.number(origin.x)..'% '..util.number(origin.y)..'%;animation:'
              ..util.number(track.duration)..'s '..cssEasing(block.easing)..' '..util.number(track.delay)..'s '
              ..tostring(block.iterations or 'infinite')..' '..direction..' '..(block.fill or 'none')..' '..id..'}'
          end
        end
      end
    end
    for i = #tracks, 1, -1 do
      local track = tracks[i]
      local opacity = not self.native and track.kind == 'opacity' and (' opacity="'..util.number(track.rest)..'"') or ''
      markup = '<g id="'..track.id..'"'..opacity..'>'..markup..'</g>'
    end
    return markup
  end
  function context:stylesheet()
    if #self.css == 0 then return '' end
    local css = table.concat(self.css)
    if options.animationRespectReducedMotion ~= false then css = '@media (prefers-reduced-motion:no-preference){'..css..'}' end
    return '<style>'..css..'</style>'
  end
  return context
end

function M.matrix(track, value, bounds)
  local a,b,c,d,e,f = 1,0,0,1,0,0
  local origin = track.block.origin or {x=50,y=50}
  local x,y = bounds[1]+bounds[3]*origin.x/100, bounds[2]+bounds[4]*origin.y/100
  if track.kind == 'translateX' then e = value
  elseif track.kind == 'translateY' then f = value
  elseif track.kind == 'rotate' then
    local angle = value*math.pi/180
    a,b,c,d = math.cos(angle),math.sin(angle),-math.sin(angle),math.cos(angle)
    e,f = x-a*x-c*y,y-b*x-d*y
  elseif track.kind == 'scaleX' then a,e = value,x*(1-value)
  elseif track.kind == 'scaleY' then d,f = value,y*(1-value) end
  return {a,b,c,d,e,f}, track.kind == 'opacity' and value or 1
end

return M
