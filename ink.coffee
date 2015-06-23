#
# INK.js
#
ansiRegex = require 'ansi-regex'
supportsColor = require 'supports-color'

SHADE_AMT = 0.1

applyDomain = (val, lb, ub, tlb, tub)->
  Math.round ((val - lb) / (ub - lb)) * (tub - tlb)

InkRender = (args...)->
  console.log 'RENDER', @

# thanks to Mohsen at http://stackoverflow.com/a/9493060/510036
rgbToHsl = (r, g, b)->
  r /= 255
  g /= 255
  b /= 255
  max = Math.max r, g, b
  min = Math.min r, g, b
  l = (max + min) / 2
  if max is min then h = s = 0 # achromatic
  else
    d = max - min
    s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
    switch max
      when r then h = (g - b) / d + (if g < b then 6 else 0)
      when g then h = (b - r) / d + 2
      when b then h = (r - g) / d + 4
    h /= 6
  return [h, s, l]

hslToRgb = (h, s, l)->
  if s is 0 then r = g = b = l # achromatic
  else
    hue2rgb = (p, q, t)->
      if t < 0 then t += 1
      if t > 1 then t -= 1
      if t < (1/6) then return p + (q - p) * 6 * t
      if t < (1/2) then return q
      if t < (2/3) then return p + (q - p) * ((2/3) - t) * 6
      return p
    q = if l < 0.5 then l * (1 + s) else l + s - l * s
    p = 2 * l - q
    r = hue2rgb p, q, h + (1/3)
    g = hue2rgb p, q, h
    b = hue2rgb p, q, h - (1/3)
  return [
    Math.round r * 255
    Math.round g * 255
    Math.round b * 255
  ]

class Ink
  constructor: ->
    @codes =
      fg: {}
      bg: {}
    @side = 'fg'

  reset:-> @codes = {}

  bold:-> @codes.bold = on
  thin:-> @codes.bold = off

  fg:-> @side = 'fg'
  bg:-> @side = 'bg'

  bright:-> # TODO
  light:-> @codes[@side].mult =     2.0
  dim:-> @codes[@side].mult =       1.0
  lighter:->
    @codes[@side].mult +=           SHADE_AMT
    (amt)=>
      --amt
      @codes[@side].mult +=         amt * SHADE_AMT

  black:-> @codes[@side].color =    [0,   0,   0  ]
  red:-> @codes[@side].color =      [127, 0,   0  ]
  green:-> @codes[@side].color =    [0,   127, 0  ]
  yellow:-> @codes[@side].color =   [127, 127, 0  ]
  blue:-> @codes[@side].color =     [0,   0,   127]
  magenta:-> @codes[@side].color =  [127, 0,   127]
  cyan:-> @codes[@side].color =     [0,   127, 127]
  white:-> @codes[@side].color =    [127, 127, 127]

# ... and a teaspoon of Javascript black voodoo magic ...
module.exports = {}

defineFnProp = (obj, name, thisArg, fn)->
  if not fn and thisArg instanceof Function
    fn = thisArg
    thisArg = null
  Object.defineProperty obj, name,
    enumerable: yes
    get: -> fn.call thisArg
  return obj

mkGetter = (ink, fn, getter)->->
  fn.call ink
  return getter

mkExport = (name, fn)->->
  ink = new Ink
  getter = InkRender.bind ink
  for name, gfn of Ink.prototype
    defineFnProp getter, name, mkGetter ink, gfn, getter
  fgbg = fn.call ink
  return getter

for name, fn of Ink.prototype
  defineFnProp module.exports, name, mkExport name, fn
