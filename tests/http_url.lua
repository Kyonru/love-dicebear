local http = require('love_dicebear.http_url')
local function contains(value, text) assert(value:find(text, 1, true), text) end
local address = http.build('initials', {seed = 'Ada & 🤖 / % "', size = 128})
contains(address, 'https://api.dicebear.com/10.x/initials/png?')
contains(address, 'seed=Ada%20%26%20%F0%9F%A4%96%20%2F%20%25%20%22')
contains(address, 'size=128')
local options = {eyesVariant = {happy = 3, dizzy = 1}, backgroundColor = {}, rotate = {-10, 10}}
address = http.build('bottts', options)
contains(address, 'eyesVariant=dizzy%3A1%2Chappy%3A3')
contains(address, 'backgroundColor=')
contains(address, 'rotate=-10%2C10')
assert(options.eyesVariant.happy == 3 and #options.backgroundColor == 0)
address = http.build('bottts', {fontFamily = 'system-ui', fontWeight = 400})
assert(not address:find('font', 1, true))
contains(http.build('bottts', {}, {baseUrl = 'http://127.0.0.1:8080/10.x/'}), 'http://127.0.0.1:8080/10.x/bottts/png?')
for _, options in ipairs({{size = 257}, {size = 1.5}, {title = 'hello'}, {fontFamily = 'Arial'}, {fontWeight = 700}}) do
  assert(not pcall(http.build, 'bottts', options))
end
local aliasVariant = require('love_dicebear').describe('blobs').options.blob01Variant.values[1]
local accepted, message = pcall(http.build, 'blobs', {blob01Variant = aliasVariant})
assert(not accepted and message:find('alias override', 1, true))
assert(not pcall(http.build, 'blobs', {blob01Probability = 0}))
assert(not pcall(http.build, 'bottts', {}, {baseUrl = 'file:///etc/passwd'}))
assert(not pcall(http.build, 'bottts', {}, {baseUrl = 'https://example.com\noutput=x'}))
assert(not pcall(http.build, 'bottts', false))
print('PASS: HTTP URLs, encoding, option boundaries, and self-hosted endpoints')
