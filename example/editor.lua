-- Descriptor-driven controls for the catalog example; not part of the library API.
local dicebear = require('love_dicebear')
local copy = require('love_dicebear.util').copy
local Editor = {}
Editor.__index = Editor
local fallbackColors = {'#ffffff', '#111827', '#448ef4', '#d95c9a', '#e8edf2', '#fbbf24', '#22c55e'}
local steps = {rotate = 5, scale = 0.1, translateX = 5, translateY = 5, borderRadius = 1, size = 16, fontWeight = 100}
local visibleRows, rowHeight = 7, 36

local function trimLast(text)
  local index = #text
  while index > 1 and text:byte(index) >= 128 and text:byte(index) < 192 do index = index - 1 end
  return text:sub(1, index - 1)
end

function Editor.new(onChange)
  return setmetatable({onChange = onChange, rows = {}, selected = 1, offset = 0}, Editor)
end

function Editor:setDescription(description)
  self.description, self.rows, self.selected, self.offset = description, {}, 1, 0
  self.input, self.message = nil, nil
  local names = {}
  for name in pairs(description.options) do names[#names + 1] = name end
  local function rank(name)
    local spec = description.options[name]
    if name == 'eyesVariant' then return 0 end
    if spec.type == 'variant' then return 1 end
    if name:match('Probability$') then return 2 end
    if spec.type == 'color' then return 3 end
    if spec.type == 'range' or spec.type == 'enum' then return 4 end
    return 5
  end
  table.sort(names, function(a, b) return rank(a) == rank(b) and a < b or rank(a) < rank(b) end)
  for _, name in ipairs(names) do
    self.rows[#self.rows + 1] = {name = name, spec = description.options[name]}
  end
end

function Editor:setState(requested, resolved, renderer)
  self.requested, self.resolved, self.renderer = requested, resolved, renderer
end

function Editor:isEnabled(row)
  if self.renderer ~= 'http' then return true end
  local name = row.name
  local component = name:match('^(.*)Probability$')
  local alias = row.spec.extends or (component and self.description.options[component .. 'Variant'].extends)
  return not alias and name ~= 'fontFamily' and name ~= 'fontWeight' and name ~= 'title'
end

function Editor:value(row)
  local value = self.resolved[row.name]
  if type(value) == 'table' then return row.spec.type == 'color' and 'transparent' or '(hidden)' end
  return value == nil and '(default)' or tostring(value)
end

function Editor:select(index)
  self.selected = (index - 1) % #self.rows + 1
  self.offset = math.max(0, math.min(self.offset, self.selected - 1))
  if self.selected > self.offset + visibleRows then self.offset = self.selected - visibleRows end
  self.message = nil
end

function Editor:apply(value, reset)
  local row = self.rows[self.selected]
  if not self:isEnabled(row) then self.message = 'This setting is local-only.'; return false end
  local edited = copy(self.requested)
  edited[row.name] = value
  if not reset and row.spec.type == 'variant' then
    edited[row.name:gsub('Variant$', 'Probability')] = 100
  end
  local ok, err = pcall(dicebear.resolve, self.description.name, edited)
  if ok and self.renderer == 'http' then ok, err = pcall(require('love_dicebear.http').url, self.description.name, edited) end
  if not ok then self.message = tostring(err); return false end
  self.onChange(edited)
  self.message = nil
  return true
end

function Editor:beginInput()
  local row = self.rows[self.selected]
  if not self:isEnabled(row) then self.message = 'This setting is local-only.'; return end
  local value = self:value(row)
  self.input = (value == '(default)' or value == '(hidden)') and '' or value
  self.replaceInput, self.message, self.ignoreOpeningText = true, nil, nil
end

function Editor:adjust(direction)
  local row = self.rows[self.selected]
  if not self:isEnabled(row) then self.message = 'This setting is local-only.'; return end
  local spec, value = row.spec, self.resolved[row.name]
  if spec.type == 'variant' or spec.type == 'enum' or spec.type == 'color' then
    local choices = copy(spec.values or (#spec.palette > 0 and spec.palette or fallbackColors))
    if spec.type == 'color' then choices[#choices + 1] = 'transparent' end
    if #choices == 0 then return end
    local current = direction > 0 and 0 or 1
    for i, choice in ipairs(choices) do if choice == value then current = i; break end end
    local chosen = choices[(current - 1 + direction) % #choices + 1]
    self:apply(chosen == 'transparent' and {} or chosen)
  elseif spec.type == 'number' or spec.type == 'range' then
    local maximum = self.renderer == 'http' and row.name == 'size' and 256 or spec.max
    local step = steps[row.name] or 10
    local number = math.max(spec.min, math.min(maximum, (value or spec.default or 256) + step * direction))
    self:apply(math.floor(number * 10000 + 0.5) / 10000)
  else self:beginInput() end
end

function Editor:keypressed(key)
  if self.input ~= nil then
    if key == 'escape' then self.input, self.message = nil, nil
    elseif key == 'backspace' then
      self.input = self.replaceInput and '' or trimLast(self.input)
      self.replaceInput = false
    elseif key == 'return' or key == 'kpenter' then
      local row, value = self.rows[self.selected], self.input
      if row.spec.type == 'number' or row.spec.type == 'range' then
        value = tonumber(value)
        if not value then self.message = 'Enter a number.'; return true end
      elseif row.spec.type == 'color' and value:lower() == 'transparent' then value = {} end
      if self:apply(value) then self.input = nil end
    end
    return true -- Typed letters must not trigger Save, Randomize, or renderer shortcuts.
  end
  if key == 'tab' then
    local backwards = love and love.keyboard and love.keyboard.isDown('lshift', 'rshift')
    self:select(self.selected + (backwards and -1 or 1))
  elseif key == 'pageup' or key == 'pagedown' then self:select(self.selected + (key == 'pageup' and -visibleRows or visibleRows))
  elseif key == 'left' or key == 'right' then self:adjust(key == 'right' and 1 or -1)
  elseif key == 'e' then self:beginInput(); self.ignoreOpeningText = self.input ~= nil
  elseif key == 'backspace' then self:apply(nil, true)
  else return false end
  return true
end

function Editor:textinput(text)
  if self.ignoreOpeningText then
    self.ignoreOpeningText = nil
    if text == 'e' or text == 'E' then return end
  end
  if self.input ~= nil then
    self.input = (self.replaceInput and '' or self.input) .. text
    self.replaceInput = false
  end
end

function Editor:mousepressed(x, y, button)
  if button ~= 1 or self.input ~= nil or x < 32 or x > 728 or y < 470 or y >= 470 + visibleRows * rowHeight then return end
  local index = self.offset + math.floor((y - 470) / rowHeight) + 1
  if not self.rows[index] then return end
  self:select(index)
  if x >= 692 then self:adjust(1)
  elseif x >= 656 then self:adjust(-1)
  elseif x >= 280 then self:beginInput() end
end

function Editor:wheelmoved(y)
  if self.input == nil then self:select(self.selected + (y > 0 and -1 or 1)) end
end

function Editor:draw()
  local g = love.graphics
  g.setColor(1, 1, 1)
  g.print('Avatar settings', 32, 438)
  g.printf((self.offset + 1) .. '–' .. math.min(#self.rows, self.offset + visibleRows) .. ' of ' .. #self.rows, 560, 438, 168, 'right')
  for slot = 1, visibleRows do
    local index, y = self.offset + slot, 470 + (slot - 1) * rowHeight
    local row = self.rows[index]
    if row then
      local selected, enabled = index == self.selected, self:isEnabled(row)
      g.setColor(selected and 0.22 or 0.13, selected and 0.28 or 0.15, selected and 0.36 or 0.18)
      g.rectangle('fill', 32, y, 696, rowHeight - 2, 3, 3)
      local shade = enabled and 1 or 0.6
      g.setColor(shade, shade, shade)
      g.print(row.name, 44, y + 9)
      local value = (selected and self.input ~= nil) and (self.input .. ' |') or self:value(row)
      if not enabled then value = value .. ' (local only)' end
      local valueX = 280
      if row.spec.type == 'color' then
        local color = self.resolved[row.name]
        if type(color) == 'string' then
          g.setColor(tonumber(color:sub(2, 3), 16) / 255, tonumber(color:sub(4, 5), 16) / 255,
            tonumber(color:sub(6, 7), 16) / 255, tonumber(color:sub(8, 9), 16) and tonumber(color:sub(8, 9), 16) / 255 or 1)
          g.rectangle('fill', 280, y + 8, 18, 18)
        end
        g.setColor(shade, shade, shade)
        g.rectangle('line', 280, y + 8, 18, 18)
        valueX = 306
      end
      while g.getFont():getWidth(value) > 640 - valueX and #value > 0 do value = trimLast(value) end
      g.print(value, valueX, y + 9)
      g.printf('-', 656, y + 9, 32, 'center')
      g.printf('+', 692, y + 9, 32, 'center')
    end
  end
  g.setColor(1, 1, 1)
  local hint = self.input ~= nil and 'Type a value • Enter: apply • Esc: cancel' or 'Tab / Shift+Tab: select • Left/Right: change • E: type • Backspace: reset'
  g.print(hint, 32, 738)
  if self.message then
    g.setColor(1, 0.72, 0.55)
    g.printf(self.message, 32, 762, 696)
  end
  g.setColor(1, 1, 1)
end

return Editor
