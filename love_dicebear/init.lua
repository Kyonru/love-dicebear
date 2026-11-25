local options = require('love_dicebear.options')
local renderer = require('love_dicebear.renderer')
local util = require('love_dicebear.util')
local M = {version = '0.1.0'}

local function style(name)
  assert(name == 'bottts', 'unsupported style: ' .. tostring(name) .. ' (available: bottts)')
  return require('love_dicebear.styles.bottts')
end

function M.styles() return {'bottts'} end

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
