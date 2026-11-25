-- Catalog example: local ThorVG or optional HTTP PNG rendering.
local dicebear = require('love_dicebear')
local document, state
local styleName, styleIndex = 'cats', 1
local animationEnabled = true
local styles = dicebear.styles()
local previewNotice
local description = dicebear.describe(styleName)
local renderer = 'thorvg'
local fontPath = 'examples/fonts/Abel-Regular.ttf'
local requested, pending, statusMessage, smoke
local cacheEnabled, forceRefresh = false, false
local lifetimes = {{label = '5 minutes', seconds = 300}, {label = '1 hour', seconds = 3600}, {label = '24 hours', seconds = 86400}}
local lifetimeIndex = 3
local copy = require('love_dicebear.util').copy
local editor = require('example.editor').new()

local function selectStyle(name)
  description = dicebear.describe(name)
  styleName = name
  for i, value in ipairs(styles) do if value == name then styleIndex = i end end
  editor:setDescription(description)
end

-- HTTP PNGs have no timelines; keep local animation preferences when switching back.
local function httpOptions(options)
  local result = copy(options)
  for name in pairs(result) do
    if name:match('^animation') or name:find('Animation', 1, true) then result[name] = nil end
  end
  return result
end

local function rebuild(options)
  options = copy(options)
  if options.animation ~= nil then animationEnabled = options.animation end
  options.animation = animationEnabled
  local nextDocument, nextState
  requested, pending, statusMessage, forceRefresh = copy(options), nil, nil, false
  previewNotice = renderer == 'thorvg' and not fontPath and require('love_dicebear.thorvg_support')[styleName] or nil
  if renderer == 'http' then
    nextState = dicebear.resolve(styleName, httpOptions(options))
    pending, previewNotice = 0.2, 'Downloading PNG…'
  elseif previewNotice then
    nextState = dicebear.resolve(styleName, options)
  else
    local fonts = fontPath and {[options.fontFamily or 'system-ui'] = fontPath} or nil
    local ok, result, resolved = pcall(require('love_dicebear.thorvg').new,
      styleName, options, {width = 256, height = 256, fonts = fonts})
    if ok then nextDocument, nextState = result, resolved
    else nextState, previewNotice = dicebear.resolve(styleName, options), tostring(result) end
  end
  if document then document:release() end
  document, state = nextDocument, nextState
  editor:setState(requested, state, renderer)
end

editor.onChange = rebuild

function love.load(args)
  if args[1] == '--animation-test' then
    local ok, err = pcall(require('tests.animation_render').run)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
    return
  end
  if args[1] == '--http-test' then
    smoke = require('tests.http_live').new()
    return
  end
  if args[1] == '--test' or args[1] == '--render-test' or args[1] == '--font-test' or args[1] == '--catalog-render-test' or args[1] == '--parity' then
    local ok, err = pcall(function()
      require('tests.run')
      require('tests.adapter')
      require('tests.editor')
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
    if arg == '--animate' then animationEnabled = true end
    if arg == '--no-animate' then animationEnabled = false end
    if arg == '--cache' then cacheEnabled = true end
    if arg == '--font' then fontPath = assert(args[i + 1], '--font requires a path inside the game') end
  end
  if args[1] == '--editor-test' then styleName, renderer = 'initials', 'thorvg' end
  selectStyle(styleName)
  love.window.setTitle('love-dicebear / Style catalog')
  rebuild({seed = 'hello-love', backgroundColor = 'e8edf2', borderRadius = 12})
  if args[1] == '--editor-test' then smoke = require('tests.editor_render').new(editor) end
end

function love.update(dt)
  if smoke then smoke:update(dt); return end
  if renderer ~= 'http' then
    if document then document:update(dt) end
    return
  end
  if pending then
    pending = pending - dt
    if pending <= 0 then
      pending = nil
      local ok, result = pcall(require('love_dicebear.http').new, styleName, httpOptions(requested), {
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
  if editor:keypressed(key) then return end
  if key == 'tab' then
    local backwards = love.keyboard.isDown('lshift', 'rshift')
    local seed = state.seed
    styleIndex = (styleIndex - 1 + (backwards and -1 or 1)) % #styles + 1
    selectStyle(styles[styleIndex])
    rebuild({seed = seed, borderRadius = 12})
  elseif key == 'a' and renderer == 'thorvg' then
    local options = copy(requested)
    options.animation = not animationEnabled
    -- A is the all-animations switch; reset per-timeline overrides to inherit it.
    for name in pairs(options) do
      if name:match('Animation$') then options[name] = nil end
    end
    rebuild(options)
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
    if renderer == 'thorvg' then
      local valid, err = pcall(require('love_dicebear.http').url, styleName, httpOptions(requested))
      if not valid then statusMessage = 'Cannot switch to HTTP: ' .. tostring(err); return end
    end
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
    {key = 'a', label = 'A  Animation: ' .. (remote and 'Unavailable (PNG)' or (animationEnabled and 'On' or 'Off')), enabled = not remote},
    {key = 'h', label = 'H  Renderer: ' .. (remote and 'HTTP PNG' or 'Local SVG'), enabled = true},
    {key = 'c', label = 'C  Disk cache: ' .. (cacheEnabled and 'On' or 'Off'), enabled = remote},
    {key = 't', label = 'T  Cache lifetime: ' .. lifetimes[lifetimeIndex].label, enabled = remote and cacheEnabled},
    {key = 'return', label = 'Enter  Refresh from server', enabled = remote},
    {key = 'delete', label = 'Delete  Clear this URL from cache', enabled = remote and document and document:getStatus() == 'ready'},
  }
end

function love.mousepressed(x, y, button)
  if not state then return end
  editor:mousepressed(x, y, button)
  if editor.input ~= nil or button ~= 1 or x < 320 or x > 728 then return end
  for i, control in ipairs(controls()) do
    local top = 60 + (i - 1) * 34
    if y >= top and y <= top + 28 and control.enabled then love.keypressed(control.key); return end
  end
end

function love.textinput(text) editor:textinput(text) end
function love.wheelmoved(_, y)
  local _, mouseY = love.mouse.getPosition()
  if state and mouseY >= 438 and y ~= 0 then editor:wheelmoved(y) end
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
    local top = 60 + (i - 1) * 34
    local hover = control.enabled and mx >= 320 and mx <= 728 and my >= top and my <= top + 28
    love.graphics.setColor(hover and 0.25 or 0.16, hover and 0.29 or 0.18, hover and 0.34 or 0.22)
    love.graphics.rectangle('fill', 320, top, 408, 28, 4, 4)
    local shade = control.enabled and 1 or 0.55
    love.graphics.setColor(shade, shade, shade)
    love.graphics.print(control.label, 332, top + 6)
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
  love.graphics.print('Tab/Shift+Tab: style    Up/Down: setting    Left/Right: change    R: new', 32, 338)
  local source = renderer
  if renderer == 'http' and document and document:getSource() == 'cache' then source = 'http / cached' end
  love.graphics.print('H: renderer (' .. source .. ')    S: save ' .. (renderer == 'http' and 'PNG' or 'SVG'), 32, 366)
  love.graphics.printf(statusMessage or ('Selected: ' .. editor.rows[editor.selected].name), 32, 394, 696)
  editor:draw()
  if smoke and smoke.capture then smoke:capture() end
end

function love.quit() if document then document:release() end end
