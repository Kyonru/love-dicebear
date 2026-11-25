local options = require('love_dicebear.options')
local renderer = require('love_dicebear.renderer')
local initials = require('love_dicebear.initials')
local util = require('love_dicebear.util')
local style = {
  meta = {}, canvas = {width = 100, height = 100, elements = {
    {type = 'component', name = 'tile'}, {type = 'component', name = 'other'},
  }},
  colors = {
    background = {values = {'#ffffff'}},
    ink = {values = {'#ffffff', '#000000'}, contrastTo = 'background'},
    accent = {values = {'#000000', '#ff0000'}, notEqualTo = {'ink'}},
  },
  components = {
    tile = {width = 10, height = 10, rotate = {min = 90, max = 90}, variants = {
      a = {elements = {{type = 'element', name = 'rect', attributes = {{'width', '10'}, {'height', '10'}, {'fill', {type = 'color', name = 'ink'}}}}}},
      b = {elements = {{type = 'element', name = 'circle', attributes = {{'r', '5'}}}}},
    }},
    other = {extends = 'tile'},
  },
}
local resolved = options.resolve(style, {seed = 'test', tileVariant = 'a'})
assert(resolved.tileVariant == 'a' and resolved.otherVariant == 'a')
assert(resolved.inkColor == '#000000' and resolved.accentColor == '#ff0000')
local svg = renderer.render(style, resolved)
assert(svg:find('rotate(90, 5, 5)', 1, true))
assert(svg == renderer.render(style, options.resolve(style, resolved)))
local edited = util.copy(resolved)
edited.otherVariant = 'b'
assert(options.resolve(style, edited).tileVariant == 'a')
assert(renderer.render(style, options.resolve(style, edited)):find('<circle', 1, true))
local cyclic = util.copy(style)
cyclic.colors.background.contrastTo = 'ink'
assert(not pcall(options.resolve, cyclic, {}))
local vectors = {
  {'Ada Lovelace', 'AL'}, {'alice', 'AL'}, {"O'Connor", 'OC'},
  {'ß Müller', 'SSM'}, {'日本語', '日本'}, {'éclair', 'ÉC'},
  {'1@Ada Lovelace', 'AL'}, {'a@\nb', 'A'}, {'🤖', ''}, {'𐐨𐐩', '𐐀𐐁'},
}
for _, v in ipairs(vectors) do assert(initials.fromSeed(v[1]) == v[2], 'initials: ' .. v[1]) end
print('PASS: shared style aliases, transforms, contrast, cycles, and Unicode initials')
