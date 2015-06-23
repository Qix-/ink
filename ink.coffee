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

InkRender = (args...)->
  console.log require('util').inspect @, colors: true, depth: null

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
