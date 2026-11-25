-- Exercise the real example layout/input without requiring optional renderers or network.
local M = {}
function M.new(editor)
  local function select(name)
    for i, row in ipairs(editor.rows) do if row.name == name then editor:select(i); return end end
    error('missing setting ' .. name)
  end
  select('backgroundColor')
  editor:beginInput(); editor:textinput('#448ef4'); editor:keypressed('return')
  assert(editor.resolved.backgroundColor == '#448ef4')
  select('rotate'); editor:adjust(1); assert(editor.resolved.rotate == 5)
  select('backgroundColor')
  local self = {phase = 1, pending = false}
  function self:update() end
  function self:capture()
    if self.pending then return end
    self.pending = true
    local phase = self.phase
    love.graphics.captureScreenshot(function(pixels)
      assert(pixels:getWidth() == 760 and pixels:getHeight() == 820)
      pixels:encode('png', phase == 1 and 'editor-settings.png' or 'editor-input.png')
      if phase == 1 then
        select('seed')
        love.keypressed('e'); love.textinput('e'); love.textinput('My avatar')
        assert(editor.input == 'My avatar')
        self.phase, self.pending = 2, false
      else
        love.keypressed('return')
        assert(editor.resolved.seed == 'My avatar')
        love.keypressed('s')
        local svg = assert(love.filesystem.read('avatar.svg'))
        assert(svg:find('#448ef4', 1, true), 'edited background was not saved')
        print('PASS: example renders settings and text input, edits multiple fields, and saves the result')
        print('Editor previews: ' .. love.filesystem.getSaveDirectory())
        love.event.quit(0)
      end
    end)
  end
  return self
end
return M
