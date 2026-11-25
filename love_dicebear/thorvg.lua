-- Optional adapter for love-thorvg's path-based API. No renderer is loaded
-- until new() is called; generation itself remains plain Lua.
local dicebear = require('love_dicebear')
local util = require('love_dicebear.util')
local M = {}
local counter = 0

function M.new(style, options, renderOptions)
  assert(love and love.filesystem, 'love_dicebear.thorvg requires LÖVE')
  local resolved = dicebear.resolve(style, options)
  local definition = require('love_dicebear.styles.' .. style)
  local svg, tracks = require('love_dicebear.renderer').render(definition, resolved, true)
  local settings = util.copy(renderOptions or {})
  if svg:find('<text[%s>]') then
    assert(type(settings.fonts) == 'table' and settings.fonts[resolved.fontFamily],
      'SVG text requires a font mapping for ' .. resolved.fontFamily .. ' in renderOptions.fonts')
  end
  local thorvg = require('love_thorvg')
  if #tracks > 0 then
    assert(thorvg.capabilities and thorvg.capabilities.svgElements,
      'Avatar animation requires love-thorvg 0.3.0 with SVG element editing')
  end
  if svg:find('<text[%s>]') then
    assert(thorvg.capabilities and thorvg.capabilities.svgFonts,
      'SVG text requires a love-thorvg build with SVG font preloading; update its Lua wrapper and native library')
  end
  -- Staged SVGs are temporary; user font paths are relative to the game root.
  if settings.assetRoot == nil then settings.assetRoot = '' end
  local directory = 'love-dicebear-temp'
  assert(love.filesystem.createDirectory(directory), 'could not create SVG staging directory')
  local path
  repeat
    counter = counter + 1
    path = directory .. '/avatar-' .. counter .. '.svg'
  until not love.filesystem.getInfo(path)
  local written, message = love.filesystem.write(path, svg)
  assert(written, message or 'could not stage SVG')
  settings.autoplay = false
  local success, document = pcall(thorvg.new, path, settings)
  local removed = love.filesystem.remove(path)
  if not success then error(document, 2) end
  if not removed then
    document:release()
    error('could not remove temporary SVG: ' .. path, 2)
  end
  local attached, result = pcall(require('love_dicebear.animation_player').attach, document, tracks, renderOptions or {})
  if not attached then document:release(); error(result, 2) end
  return document, resolved
end

return M
