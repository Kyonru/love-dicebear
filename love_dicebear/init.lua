local options = require('love_dicebear.options')
local renderer = require('love_dicebear.renderer')
local util = require('love_dicebear.util')
local M = {version = '1.0.0'}
local names = require('love_dicebear.styles.registry')
local available = {}
for _, name in ipairs(names) do available[name] = true end

local function style(name)
  assert(available[name], 'unsupported style: ' .. tostring(name) .. ' (see dicebear.styles())')
  return require('love_dicebear.styles.' .. name)
end

function M.styles() return util.copy(names) end

function M.describe(name)
  local definition = style(name)
  return {name = name, options = options.describe(definition), meta = util.copy(definition.meta)}
end

function M.resolve(name, input)
  if input == nil then input = {} end
  return options.resolve(style(name), input)
end

function M.generate(name, input)
  local definition = style(name)
  if input == nil then input = {} end
  local resolved = options.resolve(definition, input)
  return renderer.render(definition, resolved), resolved
end

return M
