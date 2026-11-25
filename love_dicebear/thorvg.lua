-- Optional adapter for love-thorvg's path-based API. No renderer is loaded
-- until new() is called; generation itself remains plain Lua.
local dicebear = require('love_dicebear')
local util = require('love_dicebear.util')
local M = {}
local counter = 0

function M.new(style, options, renderOptions)
  assert(love and love.filesystem, 'love_dicebear.thorvg requires LÖVE')
  local svg, resolved = dicebear.generate(style, options)
  assert(not svg:find('<text[%s>]'),
    'love-thorvg v0.2.0 does not reliably render SVG text; use dicebear.generate() and another renderer for this avatar')
  local thorvg = require('love_thorvg')
  local directory = 'love-dicebear-temp'
  assert(love.filesystem.createDirectory(directory), 'could not create SVG staging directory')
  local path
  repeat
    counter = counter + 1
    path = directory .. '/avatar-' .. counter .. '.svg'
  until not love.filesystem.getInfo(path)
  local written, message = love.filesystem.write(path, svg)
  assert(written, message or 'could not stage SVG')
  local settings = util.copy(renderOptions or {})
  settings.autoplay = false
  local success, document = pcall(thorvg.new, path, settings)
  local removed = love.filesystem.remove(path)
  if not success then error(document, 2) end
  if not removed then
    document:release()
    error('could not remove temporary SVG: ' .. path, 2)
  end
  return document, resolved
end

return M
