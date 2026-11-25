local d = require('love_dicebear')
local a = require('love_dicebear.animation')
local function near(actual, expected) assert(math.abs(actual-expected)<1e-6, actual..' ~= '..expected) end
local t = {block={}, duration=2, delay=0, rest=1, frames={{at=0,value=0},{at=100,value=10}}}
near(a.sample(t,0),0); near(a.sample(t,1),5); near(a.sample(t,2),0)
t.block.direction='alternate'; near(a.sample(t,3),5); near(a.sample(t,2),10)
t.block.direction='reverse'; near(a.sample(t,.5),7.5)
t.block.direction=nil; t.delay=1; near(a.sample(t,0),1)
t.block.fill='backwards'; near(a.sample(t,0),0)
t.block.iterations=1; t.block.fill='forwards'; near(a.sample(t,4),10)
t.block.fill='none'; near(a.sample(t,4),1)
near(a.easing('hold',.9),0); near(a.easing('hold',1),1)
near(a.easing('easeInOut',.5),.5)
near(a.easing({0,0,1,1},.25),.25)
local m = a.matrix({kind='rotate',block={origin={x=50,y=50}}}, 90, {0,0,10,10})
near(m[1],0);near(m[2],1);near(m[5],10);near(m[6],0)
local plain = d.generate('cats',{seed='test'})
assert(not plain:find('@keyframes',1,true))
assert(plain == d.generate('cats',{seed='test',animation=false}))
local svg,state = d.generate('cats',{seed='test',animation=true,animationSpeed={.5,2}})
assert(svg:find('@keyframes',1,true) and svg:find('prefers-reduced-motion',1,true))
assert(svg == d.generate('cats',state), 'resolved animation state must round-trip')
assert(not d.generate('cats',{animation=true,animationRespectReducedMotion=false}):find('@media',1,true))
assert(not pcall(d.generate,'cats',{animation='true'}))
assert(not pcall(d.generate,'cats',{animationSpeed=0}))
assert(not pcall(d.generate,'cats',{animationDelay=math.huge}))
local named = d.generate('cats',{seed='test',wagAnimation=true})
assert(named:find('@keyframes',1,true))
local definition = require('love_dicebear.styles.cats')
local _,tracks = require('love_dicebear.renderer').render(definition,d.resolve('cats',{animation=true,wagAnimation=false}),true)
for _,track in ipairs(tracks) do assert(track.block.name ~= 'wag') end
print('PASS: animation timing, easing, directions, fill, transforms, options, SVG export and round-trips')

local edits = 0
local fake = {handle=true, getElementBounds=function() return 0,0,10,10 end,
  setElement=function() edits=edits+1 end}
local track = {id='x',kind='translateX',block={},duration=1,delay=0,rest=0,frames={{at=0,value=0},{at=100,value=1}}}
require('love_dicebear.animation_player').attach(fake,{track},{autoplay=false})
assert(edits==1 and not fake:update(.1))
fake.playing=true
assert(fake:update(.25) and edits==2)
fake:seek(.25); assert(edits==2)
assert(not pcall(fake.seek,fake,math.huge))
assert(not pcall(fake.update,fake,-1))
fake.handle=nil
assert(not pcall(fake.seek,fake,0))
print('PASS: animation player pause, clock, unchanged frames, invalid times and released state')
