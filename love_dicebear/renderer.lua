local util = require('love_dicebear.util')
local prng = require('love_dicebear.prng')
local animation = require('love_dicebear.animation')
local M = {}
local esc, num = util.escape, util.number

local metadata = require('love_dicebear.metadata')
local initials = require('love_dicebear.initials')

local function componentTransform(component, name, seed)
  local translate = component.translate or {}
  local x = prng.float(seed, name .. 'TranslateX', translate.x, 0) / 100 * component.width
  local y = prng.float(seed, name .. 'TranslateY', translate.y, 0) / 100 * component.height
  local rotate = prng.float(seed, name .. 'Rotate', component.rotate, 0)
  local scale = prng.float(seed, name .. 'Scale', component.scale, 1)
  local cx, cy = num(component.width / 2), num(component.height / 2)
  local transforms = {}
  if x ~= 0 or y ~= 0 then transforms[#transforms + 1] = 'translate(' .. num(x) .. ', ' .. num(y) .. ')' end
  if rotate ~= 0 then transforms[#transforms + 1] = 'rotate(' .. num(rotate) .. ', ' .. cx .. ', ' .. cy .. ')' end
  if scale ~= 1 then
    transforms[#transforms + 1] = 'translate(' .. cx .. ', ' .. cy .. ') scale(' .. num(scale)
      .. ') translate(' .. num(-component.width / 2) .. ', ' .. num(-component.height / 2) .. ')'
  end
  return table.concat(transforms, ' ')
end

function M.render(style, options, nativeAnimation)
  local sourceName = ((style.meta or {}).source or {}).name or ''
  local hash = string.format('%08x', prng.hash(sourceName .. ':' .. options.seed))
  local motion = animation.context(options, hash, nativeAnimation)
  local defs, order = {}, {}
  local function define(id, svg)
    if not defs[id] then order[#order + 1] = id end
    defs[id] = svg
  end
  local function color(name)
    local value = options[name .. 'Color']
    return type(value) == 'string' and value or 'none'
  end
  local cachedInitials
  local function variable(name)
    if name == 'fontFamily' then return options.fontFamily end
    if name == 'fontWeight' then return num(options.fontWeight) end
    cachedInitials = cachedInitials or initials.fromSeed(options.seed)
    if name == 'initials' then return cachedInitials end
    if name == 'initial' then return initials.first(cachedInitials) end
    error('unsupported bundled variable: ' .. tostring(name))
  end
  local function valueOf(value)
    if type(value) ~= 'table' then return value end
    if value.type == 'color' then return color(value.name) end
    if value.type == 'variable' then return variable(value.name) end
    error('unsupported bundled value reference')
  end
  local function attrs(attributes)
    local result = {}
    for _, pair in ipairs(attributes or {}) do
      local key, value = pair[1], pair[2]
      value = valueOf(value)
      result[#result + 1] = ' ' .. key .. '="' .. esc(value) .. '"'
    end
    return table.concat(result)
  end
  local render, elements
  function elements(items)
    local result = {}
    for _, item in ipairs(items or {}) do result[#result + 1] = render(item) end
    return table.concat(result)
  end
  local function renderRaw(element)
    local name = element.name
    if element.type == 'text' then return esc(valueOf(element.value) or '') end
    if element.type == 'component' then
      if options[name .. 'Probability'] == 0 then return '' end
      local variant = options[name .. 'Variant']
      local entry = style.components[name]
      local source = entry.extends or name
      local component = style.components[source]
      local id = source .. '-' .. variant .. '-' .. hash
      local inline
      if nativeAnimation then inline = elements(component.variants[variant].elements)
      elseif not defs[id] then
        local body = elements(component.variants[variant].elements)
        define(id, '<g id="' .. id .. '">' .. body .. '</g>')
      end
      local attributes = util.copy(element.attributes or {})
      local transform = componentTransform(component, name, options.seed)
      if transform ~= '' then
        local found = false
        for _, pair in ipairs(attributes) do
          if pair[1] == 'transform' then
            pair[2] = (pair[2] ~= '' and pair[2] .. ' ' or '') .. transform
            found = true
          end
        end
        if not found then attributes[#attributes + 1] = {'transform', transform} end
      end
      if inline then return '<g' .. attrs(attributes) .. '>' .. inline .. '</g>' end
      return '<use' .. attrs(attributes) .. ' href="#' .. id .. '"/>'
    end
    assert(element.type == 'element', 'unsupported bundled element type')
    if name == 'defs' then
      for _, child in ipairs(element.children or {}) do
        local id
        for _, pair in ipairs(child.attributes or {}) do if pair[1] == 'id' then id = pair[2] end end
        local body = render(child)
        if body ~= '' then define(id or '_' .. #order, body) end
      end
      return ''
    end
    local body = elements(element.children)
    if body == '' then
      local hasId = false
      for _, pair in ipairs(element.attributes or {}) do if pair[1] == 'id' then hasId = true end end
      if element.children and #element.children > 0 and not hasId then return '' end
      return '<' .. name .. attrs(element.attributes) .. '/>'
    end
    return '<' .. name .. attrs(element.attributes) .. '>' .. body .. '</' .. name .. '>'
  end
  function render(element)
    local blocks = animation.playing(element, options)
    local original = element
    local opacity = false
    for _, block in ipairs(blocks) do if block.tracks.opacity then opacity = true end end
    if opacity then
      element = util.copy(element)
      local filtered = {}
      for _, pair in ipairs(element.attributes or {}) do
        if pair[1] ~= 'opacity' then filtered[#filtered+1] = pair end
      end
      element.attributes = filtered
    end
    return motion:wrap(renderRaw(element), original, blocks)
  end
  local w, h = style.canvas.width, style.canvas.height
  local cx, cy = num(w / 2), num(h / 2)
  local body = elements(style.canvas.elements)
  local function wrap(transform) body = '<g transform="' .. transform .. '">' .. body .. '</g>' end
  if options.scale ~= 1 then
    wrap('translate(' .. cx .. ', ' .. cy .. ') scale(' .. num(options.scale)
      .. ') translate(-' .. cx .. ', -' .. cy .. ')')
  end
  local flips = {
    horizontal = 'translate(' .. num(w) .. ', 0) scale(-1, 1)',
    vertical = 'translate(0, ' .. num(h) .. ') scale(1, -1)',
    both = 'translate(' .. num(w) .. ', ' .. num(h) .. ') scale(-1, -1)',
  }
  if flips[options.flip] then wrap(flips[options.flip]) end
  if options.rotate ~= 0 then wrap('rotate(' .. num(options.rotate) .. ', ' .. cx .. ', ' .. cy .. ')') end
  if options.translateX ~= 0 or options.translateY ~= 0 then
    wrap('translate(' .. num(options.translateX / 100 * w) .. ', ' .. num(options.translateY / 100 * h) .. ')')
  end
  -- Background stays fixed while the avatar is transformed (Core 10.7.0).
  if color('background') ~= 'none' then
    body = '<rect width="' .. num(w) .. '" height="' .. num(h) .. '" fill="'
      .. color('background') .. '"/>' .. body
  end
  local clip = 'clip-' .. hash
  define(clip, '<clipPath id="' .. clip .. '"><rect width="' .. num(w) .. '" height="'
    .. num(h) .. '" rx="' .. num(options.borderRadius / 100 * w) .. '" ry="'
    .. num(options.borderRadius / 100 * h) .. '"/></clipPath>')
  body = '<g clip-path="url(#' .. clip .. ')">' .. body .. '</g>'
  local definitions = {}
  for _, id in ipairs(order) do definitions[#definitions + 1] = defs[id] end
  local root = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' .. num(w) .. ' ' .. num(h) .. '"'
    .. attrs(style.attributes)
  if options.title ~= nil then root = root .. ' role="img" aria-label="' .. esc(options.title) .. '"'
  else root = root .. ' aria-hidden="true"' end
  if options.size then root = root .. ' width="' .. num(options.size) .. '" height="' .. num(options.size) .. '"' end
  return root .. '><!-- Generated by DiceBear (https://www.dicebear.com) -->' .. metadata(style.meta)
    .. '<defs>' .. table.concat(definitions) .. motion:stylesheet() .. '</defs>'
    .. (options.title ~= nil and '<title>' .. esc(options.title) .. '</title>' or '') .. body .. '</svg>', motion.tracks
end

return M
