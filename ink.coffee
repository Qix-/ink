#
# INK.js
#
ansiRegex = require 'ansi-regex'
supportsColor = require 'supports-color'
Color = require 'color-js'

DEFAULT_AMT = 0.1

clamp = (v, l, u)-> Math.min u, Math.max l, v

applyDomain = (val, lb, ub, tlb, tub)->
  Math.round ((val - lb) / (ub - lb)) * (tub - tlb)

toAnsi16 = (col)->
  rgb = col.toRGB()
  r = applyDomain rgb.red, 0.0, 1.0, 0, 1
  g = applyDomain rgb.green, 0.0, 1.0, 0, 1
  b = applyDomain rgb.blue, 0.0, 1.0, 0, 1

  g <<= 1
  b <<= 2
  return r | g | b

toAnsi256 = (col)->
  rgb = col.toRGB()
  r = applyDomain rgb.red, 0.0, 1.0, 0, 5
  g = applyDomain rgb.green, 0.0, 1.0, 0, 5
  b = applyDomain rgb.blue, 0.0, 1.0, 0, 5
  return (36 * r) + (6 * g) + b + 16

toAnsi16m = (col)->
  rgb = col.toRGB()
  r = applyDomain rgb.red, 0.0, 1.0, 0, 255
  g = applyDomain rgb.green, 0.0, 1.0, 0, 255
  b = applyDomain rgb.blue, 0.0, 1.0, 0, 255
  return "#{r};#{g};#{b}"

InkRender = (args...)->
  if not supportsColor
    args = args.join ' '
  else
    # TODO this could *greatly* be improved
    openCode = [
      # TODO put codes here
      0
      if @codes.bold then 1
      if @codes.fg.color then switch supportsColor.level
        when 1 then 30 + toAnsi16 @codes.fg.color
        when 2 then '38;5;' + toAnsi256 @codes.fg.color
        when 3 then '48;2;' + toAnsi16m @codes.fg.color
      if @codes.bg.color then switch supportsColor.level
        when 1 then 40 + toAnsi16 @codes.bg.color
        when 2 then '48;5;' + toAnsi256 @codes.bg.color
        when 3 then '48;2;' + toAnsi16m @codes.bg.color
    ].filter((c)->c).join ';'
    args = args
      .map (arg)-> "\x1b[#{openCode}m#{arg}\x1b[0m"
      .join ' '
  return args

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
    amt -= DEFAULT_AMT
    @[@_lastcall] amt

  to:-> (amt)->
    # _lastcall is set by the wrappers
    return if @_lastcall is 'by' or @_lastcall[0] is '_'
    @[@_lastcall] amt, yes

  lighten: (amt = DEFAULT_AMT, abs = no)->
    @codes[@side].color =
      if abs then @codes[@side].color.setLightness amt
      else @codes[@side].color.lightenByAmount amt

  darken: (amt = DEFAULT_AMT, abs = no)->
    @codes[@side].color =
      if abs then @codes[@side].color.setLightness amt
      else @codes[@side].color.darkenByAmount amt

  black:-> @codes[@side].color =    Color [0,   0,   0  ]
  red:-> @codes[@side].color =      Color [128, 0,   0  ]
  green:-> @codes[@side].color =    Color [0,   128, 0  ]
  yellow:-> @codes[@side].color =   Color [128, 128, 0  ]
  blue:-> @codes[@side].color =     Color [0,   0,   128]
  magenta:-> @codes[@side].color =  Color [128, 0,   128]
  cyan:-> @codes[@side].color =     Color [0,   128, 128]
  white:-> @codes[@side].color =    Color [128, 128, 128]

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
