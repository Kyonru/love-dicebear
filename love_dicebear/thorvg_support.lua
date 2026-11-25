-- Text styles need an explicitly supplied font and SVG font preloading support.
-- Other styles can use the original love-thorvg v0.2.0 renderer unchanged.
return {
  initials = 'SVG text needs a font. Start with --font examples/fonts/Abel-Regular.ttf and an SVG-font-capable love-thorvg build. H: HTTP preview. S: save SVG.',
  ['initial-face'] = 'The letter shape needs a font. Start with --font examples/fonts/Abel-Regular.ttf and an SVG-font-capable love-thorvg build. H: HTTP preview. S: save SVG.',
}
