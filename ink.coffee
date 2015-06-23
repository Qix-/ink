#
# INK.js
#
ansiRegex = require 'ansi-regex'
supportsColor = require 'supports-color'

ADJUST_AMT = 0.02

clamp = (v, l, u)-> Math.min u, Math.max l, v

applyDomain = (val, lb, ub, tlb, tub)->
  Math.round ((val - lb) / (ub - lb)) * (tub - tlb)

InkRender = (args...)->
  console.log require('util').inspect @, colors: true, depth: null

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
    @lastProp = null

  reset:-> @codes = {}

  bold:-> @codes.bold = on
  thin:-> @codes.bold = off

  fg:-> @side = 'fg'
  bg:-> @side = 'bg'

  by:-> (amt)->
    # _lastcall is set by the wrappers
    return if @_lastcall is 'by' or @_lastcall[0] is '_'
    amt -= 1
    @[@_lastcall] amt

  lighter: (amt = 1)->
    amt *= ADJUST_AMT
    @_addLum amt

  black:-> @codes[@side].color =    [0,   0,   0  ]
  red:-> @codes[@side].color =      [127, 0,   0  ]
  green:-> @codes[@side].color =    [0,   127, 0  ]
  yellow:-> @codes[@side].color =   [127, 127, 0  ]
  blue:-> @codes[@side].color =     [0,   0,   127]
  magenta:-> @codes[@side].color =  [127, 0,   127]
  cyan:-> @codes[@side].color =     [0,   127, 127]
  white:-> @codes[@side].color =    [127, 127, 127]

  _addLum: (lum)->
    hsl = rgbToHsl.apply null, @codes[@side].color
    hsl[2] = clamp hsl[2] + lum, 0, 1
    @codes[@side].color = hslToRgb.apply null, hsl

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

mkGetter = (ink, name, fn, getter, bind = no)->->
  if bind
    res = fn.apply ink, arguments
  else
    res = fn.call ink
  if res instanceof Function
    res = mkGetter ink, name, res, getter, yes
    return res
  else
    ink._lastcall = name
  return getter

mkExport = (name, fn)->->
  ink = new Ink
  getter = InkRender.bind ink
  for name, gfn of Ink.prototype when name[0] isnt '_'
    defineFnProp getter, name, mkGetter ink, name, gfn, getter
  fgbg = fn.call ink
  ink._lastcall = name
  return getter

for name, fn of Ink.prototype when name[0] isnt '_'
  defineFnProp module.exports, name, mkExport name, fn
