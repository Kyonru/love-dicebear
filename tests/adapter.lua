-- Exercise filesystem cleanup and error propagation without a native dependency.
local oldLove, oldThorvg = love, package.loaded.love_thorvg
local files, failLoad, failWrite = {}, false, false
local released = false
local ok, message = pcall(function()
  love = {filesystem = {
    createDirectory = function() return true end,
    getInfo = function(path) return files[path] end,
    write = function(path, bytes)
      if failWrite then return nil, 'disk full' end
      files[path] = bytes; return true
    end,
    remove = function(path) files[path] = nil; return true end,
  }}
  package.loaded.love_thorvg = {new = function(path, settings)
    assert(files[path]:find('<svg', 1, true), 'adapter did not write SVG')
    assert(settings.autoplay == false and settings.width == 128)
    if failLoad then error('renderer failure') end
    return {release = function() released = true end}
  end}
  local adapter = require('love_dicebear.thorvg')
  local settings = {width = 128, autoplay = true}
  local document, state = adapter.new('bottts', {seed = 'adapter'}, settings)
  assert(state.seed == 'adapter' and document.release)
  assert(next(files) == nil, 'temporary SVG leaked')
  assert(settings.autoplay == true, 'render options mutated')
  local supported, textError = pcall(adapter.new, 'initials', {seed = 'Ada'}, settings)
  assert(not supported and tostring(textError):find('SVG text', 1, true))
  assert(next(files) == nil, 'unsupported text leaked a temporary SVG')
  failLoad = true
  local success, err = pcall(adapter.new, 'bottts', {}, settings)
  assert(not success and tostring(err):find('renderer failure', 1, true))
  assert(next(files) == nil, 'failed load leaked SVG')
  failWrite = true
  success, err = pcall(adapter.new, 'bottts', {}, settings)
  assert(not success and tostring(err):find('disk full', 1, true))
  document:release(); assert(released)
end)
love, package.loaded.love_thorvg = oldLove, oldThorvg
assert(ok, message)
print('PASS: ThorVG adapter lifecycle and failure cleanup')
