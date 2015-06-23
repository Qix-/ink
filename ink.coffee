#
# INK.js
#
ansiRegex = require 'ansi-regex'
supportsColor = require 'supports-color'

defineFnProp = (obj, name, thisArg, fn)->
  if not fn and thisArg instanceof Function
    fn = thisArg
    thisArg = null
  Object.defineProperty obj, name,
    enumerable: yes
    get: -> fn.call thisArg
  return obj

InkRender = (args...)->
  console.log 'RENDER', @

class InkFGBG
  constructor: (@ink, @side)->
    console.log 'FGBG:', @side

  red: ->
    console.log 'RED'

class Ink
  bold: ->
    console.log 'BOLD'

  reset: ->
    console.log 'RESET'

  fg: ->
    new InkFGBG @, 'fg'

  bg: ->
    new InkFGBG @, 'bg'

# ... and a teaspoon of Javascript black voodoo magic ...
module.exports = {}

mkGetter = (ink, fn, getter)->->
  fgbg = fn.call ink
  if fgbg instanceof InkFGBG
    fgbggetter = InkRender.bind ink
    for name, gfn of InkFGBG.prototype
      defineFnProp fgbggetter, name, mkGetter ink, gfn, getter
    fgbggetter
  else
    getter

mkExport = (name, fn)->->
  ink = new Ink
  getter = InkRender.bind ink
  for name, gfn of Ink.prototype
    defineFnProp getter, name, mkGetter ink, gfn, getter
  fgbg = fn.call ink
  return if fgbg instanceof InkFGBG then fgbg else getter

for name, fn of Ink.prototype
  defineFnProp module.exports, name, mkExport name, fn
