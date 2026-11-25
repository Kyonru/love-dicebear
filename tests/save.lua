-- Exercise the example's S key, including LÖVE's optional byte-count argument.
local dicebear = require('love_dicebear')
local oldLove, oldAdapter = love, package.loaded['love_dicebear.thorvg']
local oldHttp = package.loaded['love_dicebear.http']
local saved, settings, savedPath, lastRequest, clearedUrl, renderSettings
local ok, message = pcall(function()
  love = {
    window = {setTitle = function() end},
    filesystem = {
      write = function(path, data, size)
        assert(size == nil, 'save passed resolved settings as the byte count')
        assert(path == 'avatar.svg' or path == 'avatar.png')
        saved, savedPath = data, path
        return true
      end,
      getSaveDirectory = function() return '/example-save-directory' end,
    },
  }
  package.loaded['love_dicebear.thorvg'] = {new = function(style, input, config)
    renderSettings = config
    settings = dicebear.resolve(style, input)
    return {release = function() end}, settings
  end}
  package.loaded['love_dicebear.http'] = {new = function(style, input, config)
    assert(style == 'initials' and input.seed == 'hello-love')
    assert(config.cache == false or type(config.cache) == 'table')
    lastRequest = {config = config, status = 'loading', url = 'https://example.test/avatar.png'}
    function lastRequest:update() self.status = 'ready'; return self.status end
    function lastRequest:getStatus() return self.status end
    function lastRequest:getSource() return 'cache' end
    function lastRequest:save(path)
      assert(self.status == 'ready'); return love.filesystem.write(path, 'PNG bytes')
    end
    function lastRequest:release() self.released = true end
    return lastRequest
  end, clearCache = function(url) clearedUrl = url; return true end}
  assert(loadfile('main.lua'))()
  love.load({})
  love.keypressed('right')
  love.keypressed('s')
  assert(saved == dicebear.generate('bottts', settings), 'saved SVG differs from current avatar')
  local originalEyes = settings.eyesVariant
  love.keypressed('tab'); love.keypressed('right'); love.keypressed('s')
  assert(settings.eyesVariant == originalEyes, 'editing another component changed eyes')
  assert(saved == dicebear.generate('bottts', settings), 'non-eye edits were not saved')
  love.load({'--style', 'lorelei'})
  love.keypressed('right')
  love.keypressed('s')
  assert(saved == dicebear.generate('lorelei', settings), 'selected style was not saved')
  love.load({'--style', 'initials'})
  love.keypressed('s')
  assert(saved == dicebear.generate('initials', {
    seed = 'hello-love', backgroundColor = 'e8edf2', borderRadius = 12,
  }), 'text-only style cannot be exported without a preview')
  love.keypressed('down')
  love.keypressed('s')
  local names = dicebear.styles()
  local nextStyle
  for i, name in ipairs(names) do if name == 'initials' then nextStyle = names[i % #names + 1] end end
  assert(saved == dicebear.generate(nextStyle, settings), 'style navigation retained stale settings')
  love.load({'--renderer', 'http', '--style', 'initials', '--cache'})
  love.keypressed('s')
  assert(savedPath == 'avatar.svg', 'saving before download completion wrote a file')
  love.update(0.21)
  love.keypressed('s')
  assert(savedPath == 'avatar.png' and saved == 'PNG bytes', 'HTTP mode did not save PNG')
  local previous = lastRequest
  love.keypressed('return'); love.update(0.21)
  assert(previous.released and lastRequest.config.refresh, 'refresh did not replace the previous request')
  assert(lastRequest.config.cache.ttl == 86400)
  love.keypressed('t'); love.update(0.21)
  assert(lastRequest.config.cache.ttl == 300, 'TTL control did not apply')
  love.mousepressed(330, 108, 1); love.update(0.21)
  assert(lastRequest.config.cache == false, 'cache button did not disable caching')
  love.keypressed('c'); love.update(0.21)
  assert(lastRequest.config.cache.ttl == 300, 'cache toggle forgot TTL')
  love.keypressed('delete')
  assert(clearedUrl == lastRequest.url and not lastRequest.released, 'clear cache discarded preview or used wrong URL')
  previous = lastRequest
  love.keypressed('h'); love.keypressed('s')
  assert(previous.released and savedPath == 'avatar.svg', 'renderer switch did not release HTTP image or restore SVG saving')
  love.load({'--style', 'initials', '--font', 'examples/fonts/Abel-Regular.ttf'})
  assert(renderSettings.fonts['system-ui'] == 'examples/fonts/Abel-Regular.ttf', 'example did not pass the supplied font')
  love.keypressed('s')
  assert(savedPath == 'avatar.svg')
end)
love, package.loaded['love_dicebear.thorvg'] = oldLove, oldAdapter
package.loaded['love_dicebear.http'] = oldHttp
assert(ok, message)
print('PASS: example saves the edited avatar with the correct write arguments')
