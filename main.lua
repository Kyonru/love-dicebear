-- Catalog example: local ThorVG or optional HTTP PNG rendering.
local dicebear = require('love_dicebear')
local document, state, variantIndex
local styleName, styleIndex = 'bottts', 1
local styles = dicebear.styles()
local part = 'eyes'
local previewNotice
local description = dicebear.describe(styleName)
local variants = dicebear.describe('bottts').options.eyesVariant.values
local renderer = 'thorvg'
local fontPath
local requested, pending, statusMessage, smoke
local cacheEnabled, forceRefresh = false, false
local lifetimes = {{label = '5 minutes', seconds = 300}, {label = '1 hour', seconds = 3600}, {label = '24 hours', seconds = 86400}}
local lifetimeIndex = 3
local copy = require('love_dicebear.util').copy

local function selectStyle(name)
  description = dicebear.describe(name)
  styleName = name
  for i, value in ipairs(styles) do if value == name then styleIndex = i end end
  part = description.options.eyesVariant and 'eyes' or nil
  if not part then
    local parts = {}
    for key, spec in pairs(description.options) do
      if spec.type == 'variant' and not spec.extends then parts[#parts + 1] = key:sub(1, -8) end
    end
    table.sort(parts)
    part = parts[1]
  end
  variants = part and description.options[part .. 'Variant'].values or {}
end

local function rebuild(options)
  local nextDocument, nextState
  requested, pending, statusMessage, forceRefresh = copy(options), nil, nil, false
  previewNotice = renderer == 'thorvg' and not fontPath and require('love_dicebear.thorvg_support')[styleName] or nil
  if renderer == 'http' then
    nextState = dicebear.resolve(styleName, options)
    pending, previewNotice = 0.2, 'Downloading PNG…'
  elseif previewNotice then
    nextState = dicebear.resolve(styleName, options)
  else
    local fonts = fontPath and {['system-ui'] = fontPath} or nil
    local ok, result, resolved = pcall(require('love_dicebear.thorvg').new,
      styleName, options, {width = 256, height = 256, fonts = fonts})
    if ok then nextDocument, nextState = result, resolved
    else nextState, previewNotice = dicebear.resolve(styleName, options), tostring(result) end
  end
  if document then document:release() end
  document, state = nextDocument, nextState
  variantIndex = 1
  for i, variant in ipairs(variants) do if variant == state[part .. 'Variant'] then variantIndex = i end end
end

function love.load(args)
  if args[1] == '--http-test' then
    smoke = require('tests.http_live').new()
    return
  end
  if args[1] == '--test' or args[1] == '--render-test' or args[1] == '--font-test' or args[1] == '--catalog-render-test' or args[1] == '--parity' then
    local ok, err = pcall(function()
      require('tests.run')
      require('tests.adapter')
      require('tests.http_url')
      require('tests.http')
      require('tests.http_worker')
      if args[1] == '--font-test' then require('tests.font_render')() end
      if args[1] == '--render-test' then require('tests.render')() end
      if args[1] == '--catalog-render-test' then require('tests.catalog_render')() end
      if args[1] == '--parity' then
        arg = {args[2]}
        require('tests.parity')
      end
    end)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
    return
  end
  for i, arg in ipairs(args) do
    if arg == '--style' then styleName = assert(args[i + 1], '--style requires a name') end
    if arg == '--renderer' then
      renderer = args[i + 1]
      assert(renderer == 'thorvg' or renderer == 'http', '--renderer must be thorvg or http')
    end
    if arg == '--cache' then cacheEnabled = true end
    if arg == '--font' then fontPath = assert(args[i + 1], '--font requires a path inside the game') end
  end
  selectStyle(styleName)
  love.window.setTitle('love-dicebear / Style catalog')
  rebuild({seed = 'hello-love', backgroundColor = 'e8edf2', borderRadius = 12})
end

function love.update(dt)
  if smoke then smoke:update(dt); return end
  if renderer ~= 'http' then return end
  if pending then
    pending = pending - dt
    if pending <= 0 then
      pending = nil
      local ok, result = pcall(require('love_dicebear.http').new, styleName, requested, {
        cache = cacheEnabled and {ttl = lifetimes[lifetimeIndex].seconds} or false, refresh = forceRefresh,
      })
      if ok then document = result
      else previewNotice = tostring(result) .. '\nEnter: retry' end
    end
  end
  if document then
    local status = document:update()
    if status == 'error' then previewNotice = document:getError():sub(1, 180) .. '\nEnter: retry'
    elseif status == 'queued' then previewNotice = 'Waiting for the previous download…'
    elseif status == 'loading' then previewNotice = 'Downloading PNG…'
    elseif status == 'ready' then previewNotice = nil end
  end
end

function love.keypressed(key)
  if not state then return end
  if key == 'right' or key == 'left' then
    if #variants == 0 then return end
    variantIndex = (variantIndex - 1 + (key == 'right' and 1 or -1)) % #variants + 1
    local edited = copy(requested)
    edited[part .. 'Variant'] = variants[variantIndex]
    edited[part .. 'Probability'] = 100
    rebuild(edited)
  elseif key == 'up' or key == 'down' then
    local seed = state.seed
    styleIndex = (styleIndex - 1 + (key == 'down' and 1 or -1)) % #styles + 1
    selectStyle(styles[styleIndex])
    rebuild({seed = seed, borderRadius = 12})
  elseif key == 'r' then
    rebuild({seed = tostring(love.timer.getTime()), backgroundColor = 'e8edf2', borderRadius = 12})
  elseif key == 's' then
    local filename, ok, message
    if renderer == 'http' then
      filename = 'avatar.png'
      if document then ok, message = document:save(filename)
      else message = 'PNG is not ready to save' end
    else
      filename = 'avatar.svg'
      local svg = dicebear.generate(styleName, state)
      ok, message = love.filesystem.write(filename, svg)
    end
    statusMessage = ok and ('Saved ' .. filename) or (message or 'Save failed')
    if ok then print('Saved ' .. love.filesystem.getSaveDirectory() .. '/' .. filename) end
  elseif key == 'h' then
    renderer = renderer == 'http' and 'thorvg' or 'http'
    rebuild(requested)
  elseif key == 'c' and renderer == 'http' then
    cacheEnabled = not cacheEnabled
    rebuild(requested)
  elseif key == 't' and renderer == 'http' and cacheEnabled then
    lifetimeIndex = lifetimeIndex % #lifetimes + 1
    rebuild(requested)
  elseif key == 'delete' and renderer == 'http' and document and document:getStatus() == 'ready' then
    local ok, message = require('love_dicebear.http').clearCache(document.url)
    statusMessage = ok and 'Cached avatar cleared; preview kept.' or (message or 'Could not clear cache')
  elseif key == 'return' and renderer == 'http' then
    rebuild(requested)
    forceRefresh = true
  elseif key == 'escape' then love.event.quit() end
end

-- Share the same actions and enabled states between mouse and keyboard controls.
local function controls()
  local remote = renderer == 'http'
  return {
    {key = 'h', label = 'H  Renderer: ' .. (remote and 'HTTP PNG' or 'Local SVG'), enabled = true},
    {key = 'c', label = 'C  Disk cache: ' .. (cacheEnabled and 'On' or 'Off'), enabled = remote},
    {key = 't', label = 'T  Cache lifetime: ' .. lifetimes[lifetimeIndex].label, enabled = remote and cacheEnabled},
    {key = 'return', label = 'Enter  Refresh from server', enabled = remote},
    {key = 'delete', label = 'Delete  Clear this URL from cache', enabled = remote and document and document:getStatus() == 'ready'},
  }
end

function love.mousepressed(x, y, button)
  if button ~= 1 or not state or x < 320 or x > 728 then return end
  for i, control in ipairs(controls()) do
    local top = 60 + (i - 1) * 40
    if y >= top and y <= top + 32 and control.enabled then love.keypressed(control.key); return end
  end
end

function love.draw()
  if not state then return end
  love.graphics.clear(0.08, 0.09, 0.11)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', 32, 32, 256, 256)
  if document and not previewNotice then document:draw(32, 32)
  else
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.printf(previewNotice or '', 48, 90, 224, 'center')
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.print('Rendering options', 320, 32)
  local mx, my = love.mouse.getPosition()
  for i, control in ipairs(controls()) do
    local top = 60 + (i - 1) * 40
    local hover = control.enabled and mx >= 320 and mx <= 728 and my >= top and my <= top + 32
    love.graphics.setColor(hover and 0.25 or 0.16, hover and 0.29 or 0.18, hover and 0.34 or 0.22)
    love.graphics.rectangle('fill', 320, top, 408, 32, 4, 4)
    local shade = control.enabled and 1 or 0.55
    love.graphics.setColor(shade, shade, shade)
    love.graphics.print(control.label, 332, top + 8)
  end
  love.graphics.setColor(1, 1, 1)
  local detail = 'Local generation. Switch to HTTP for cache options.'
  if renderer == 'http' then
    local source = document and document:getSource()
    detail = source and ('Image source: ' .. (source == 'cache' and 'disk cache' or 'network')) or 'Waiting for image…'
    if document and document:getCacheError() then detail = detail .. '\nCache: ' .. document:getCacheError() end
  end
  love.graphics.printf(detail, 320, 266, 408)
  love.graphics.print(styleName .. ' / ' .. ((description.meta.creator or {}).name or 'Unknown'), 32, 310)
  love.graphics.print('Up/Down: style    Left/Right: variant    R: new', 32, 338)
  local source = renderer
  if renderer == 'http' and document and document:getSource() == 'cache' then source = 'http / cached' end
  love.graphics.print('H: renderer (' .. source .. ')    S: save ' .. (renderer == 'http' and 'PNG' or 'SVG'), 32, 366)
  love.graphics.print(statusMessage or (part and (part .. ': ' .. tostring(state[part .. 'Variant'])) or ''), 32, 394)
end

function love.quit() if document then document:release() end end
