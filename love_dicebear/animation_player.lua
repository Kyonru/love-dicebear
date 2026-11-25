local animation = require('love_dicebear.animation')
local M = {}

local function finite(value, name)
  assert(type(value) == 'number' and value == value and math.abs(value) < math.huge, name .. ' must be finite')
  return value
end

function M.attach(document, tracks, settings)
  if #tracks == 0 then return document end
  local bounds = {}
  local duration = 0
  -- Capture every resting box before applying any parent or child animation.
  for i, track in ipairs(tracks) do
    if track.kind == 'rotate' or track.kind == 'scaleX' or track.kind == 'scaleY' then
      bounds[i] = {document:getElementBounds(track.id)}
    else bounds[i] = {0,0,0,0} end
    duration = math.max(duration, math.max(0, track.delay) + track.duration)
  end
  document.duration = duration
  document.animationTime = 0
  document.playing = settings.autoplay ~= false
  document.speed = settings.speed or 1
  finite(document.speed, 'speed')
  local previous
  function document:seek(seconds)
    assert(self.handle ~= nil, 'document has been released')
    seconds = math.max(0, finite(seconds, 'time'))
    if previous == seconds then return self end
    for i, track in ipairs(tracks) do
      local value = animation.sample(track, seconds)
      local matrix, opacity = animation.matrix(track, value, bounds[i])
      self:setElement(track.id, matrix, opacity)
    end
    previous, self.animationTime, self.time = seconds, seconds, seconds
    return self
  end
  function document:setProgress(progress)
    return self:seek(math.max(0, math.min(1, finite(progress, 'progress'))) * self.duration)
  end
  function document:update(dt)
    assert(self.handle ~= nil, 'document has been released')
    finite(dt, 'dt')
    assert(dt >= 0, 'dt must be nonnegative')
    if not self.playing or dt == 0 or self.speed == 0 then return false end
    finite(self.speed, 'speed')
    local nextTime = math.max(0, self.animationTime + dt*self.speed)
    if settings.loop == false and nextTime >= self.duration then
      nextTime = math.max(0, self.duration - 1e-9)
      self.playing = false
    end
    self:seek(nextTime)
    return true
  end
  document:seek((settings.progress or 0) * duration)
  return document
end

return M
