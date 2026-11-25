local util = require('love_dicebear.util')
local prng = require('love_dicebear.prng')
local M = {}
local esc, num = util.escape, util.number

local function metadata(meta)
  local source, creator, license = meta.source, meta.creator, meta.license
  local rights = 'Remix of “' .. source.name .. '” (' .. source.url .. ') by “'
    .. creator.name .. '”, licensed under “' .. license.name .. '” (' .. license.url .. ')'
  return '<metadata xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"'
    .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
    .. ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">'
    .. '<rdf:RDF><rdf:Description><dc:title>' .. esc(source.name) .. '</dc:title>'
    .. '<dc:creator>' .. esc(creator.name) .. '</dc:creator>'
    .. '<dc:source xsi:type="dcterms:URI">' .. esc(source.url) .. '</dc:source>'
    .. '<dcterms:license xsi:type="dcterms:URI">' .. esc(license.url) .. '</dcterms:license>'
    .. '<dc:rights>' .. esc(rights) .. '</dc:rights></rdf:Description></rdf:RDF></metadata>'
end

function M.render(style, options)
  local hash = string.format('%08x', prng.hash(style.meta.source.name .. ':' .. options.seed))
  local defs, order = {}, {}
  local function define(id, svg)
    if not defs[id] then order[#order + 1] = id end
    defs[id] = svg
  end
  local function color(name)
    local value = options[name .. 'Color']
    return type(value) == 'string' and value or 'none'
  end
  local function attrs(attributes)
    local result = {}
    for _, pair in ipairs(attributes or {}) do
      local key, value = pair[1], pair[2]
      if type(value) == 'table' then
        assert(value.type == 'color', 'unsupported bundled attribute reference')
        value = color(value.name)
      end
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
  function render(element)
    local name = element.name
    if element.type == 'component' then
      if options[name .. 'Probability'] == 0 then return '' end
      local variant = options[name .. 'Variant']
      local id = name .. '-' .. variant .. '-' .. hash
      if not defs[id] then
        local body = elements(style.components[name].variants[variant].elements)
        define(id, '<g id="' .. id .. '">' .. body .. '</g>')
      end
      return '<use' .. attrs(element.attributes) .. ' href="#' .. id .. '"/>'
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
    .. '<defs>' .. table.concat(definitions) .. '</defs>'
    .. (options.title ~= nil and '<title>' .. esc(options.title) .. '</title>' or '') .. body .. '</svg>'
end

return M
