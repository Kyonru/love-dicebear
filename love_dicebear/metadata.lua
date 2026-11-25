-- DiceBear Core 10.7.0 license metadata; see vendor/DICEBEAR-LICENSE.
local esc = require('love_dicebear.util').escape
return function(meta)
  meta = meta or {}
  local source, creator, license = meta.source or {}, meta.creator or {}, meta.license or {}
  local rights = ''
  if source.name or creator.name or license.name then
    local title = source.name and '“' .. source.name .. '”' or 'Design'
    if source.url then title = title .. ' (' .. source.url .. ')' end
    if license.name ~= 'MIT' and creator.name ~= 'DiceBear' and source.name then rights = 'Remix of ' end
    rights = rights .. title .. ' by “' .. (creator.name or 'Unknown') .. '”'
    if license.name then
      rights = rights .. ', licensed under “' .. license.name .. '”'
      if license.url then rights = rights .. ' (' .. license.url .. ')' end
    end
  end
  local fields = {}
  local function field(tag, value, attribute)
    if value then fields[#fields + 1] = '<' .. tag .. (attribute or '') .. '>' .. esc(value) .. '</' .. tag .. '>' end
  end
  field('dc:title', source.name)
  field('dc:creator', creator.name)
  field('dc:source', source.url, ' xsi:type="dcterms:URI"')
  field('dcterms:license', license.url, ' xsi:type="dcterms:URI"')
  if rights ~= '' then field('dc:rights', rights) end
  if #fields == 0 then return '' end
  return '<metadata xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"'
    .. ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
    .. ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">'
    .. '<rdf:RDF><rdf:Description>' .. table.concat(fields) .. '</rdf:Description></rdf:RDF></metadata>'
end
