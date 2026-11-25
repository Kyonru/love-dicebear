local M = {}
function M.run()
  local d = require('love_dicebear')
  local a = require('love_dicebear.animation')
  local adapter = require('love_dicebear.thorvg')
  local count = 0
  local artifact = os.getenv('LOVEDICEBEAR_ANIMATION_ARTIFACT')
  local sheet = artifact and love.image.newImageData(768, 896)
  for _, name in ipairs(d.styles()) do
    local definition = require('love_dicebear.styles.'..name)
    if #a.names(definition) > 0 then
      local seed, tracks
      for attempt = 1, 40 do
        seed = 'animation-proof-' .. attempt
        local _, selected = require('love_dicebear.renderer').render(definition, d.resolve(name, {seed=seed,animation=true}), true)
        tracks = selected
        if #tracks > 0 then break end
      end
      assert(#tracks > 0, 'could not select animated artwork: '..name)
      local doc = adapter.new(name, {seed=seed, animation=true}, {
        width=128, height=128, fonts={['system-ui']='examples/fonts/Abel-Regular.ttf'}, autoplay=false,
      })
      local before = doc:getImageData():getString()
      local x, y = (count % 3)*256, math.floor(count/3)*128
      if sheet then sheet:paste(doc:getImageData(),x,y,0,0,128,128) end
      local texture = doc:getImage()
      local changed = false
      local times = {.17,.43,.91,1.4,2.7,4.3}
      for _, track in ipairs(tracks) do
        for _, frame in ipairs(track.frames) do
          if frame.value ~= track.rest then times[#times+1] = track.delay + track.duration*frame.at/100 end
        end
      end
      for _, time in ipairs(times) do
        doc:seek(time)
        local after = doc:getImageData():getString()
        if after ~= before and not changed then
          changed = true
          if sheet then sheet:paste(doc:getImageData(),x+128,y,0,0,128,128) end
        end
        assert(doc:getImage() == texture, 'animation reallocated texture: '..name)
      end
      assert(changed, 'no animated pixels: '..name)
      doc:seek(0)
      assert(doc:getImageData():getString() == before, 'seek is not deterministic: '..name)
      doc:resize(192,192)
      doc:seek(.43)
      doc:render()
      doc:pause()
      assert(not doc:update(.1))
      doc:play()
      assert(doc:update(.1))
      doc:release()
      count=count+1
      print('PASS animated pixels: '..name)
    end
  end
  if sheet then
    local encoded = sheet:encode('png')
    local file = assert(io.open(artifact, 'wb')); file:write(encoded:getString()); file:close()
    encoded:release(); sheet:release()
  end
  assert(count >= 21)
  print('PASS: '..count..' animated styles, seek, resize, pause/play and texture reuse')
end
return M
