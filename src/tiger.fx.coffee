Tiger = require '/lib/tiger'


FX =
  fadeIn: (duration, callback) ->
    @element.visible = true
    @fadeTo 1, duration, callback

  fadeOut: (duration, callback) ->
    cb = =>
      @element.visible = false
      callback() if callback
    @fadeTo 0, duration, cb
  
  fadeTo: (opacity, duration, callback) ->
    @animate {opacity: opacity, duration: duration}, callback

  slideUp: (duration, callback) ->
    cb = =>
      @element.visible = false
      callback() if callback
    @animate {top: '-' + @get('height'), duration: duration}, cb

  slideDown: (duration, callback) ->
    @element.visible = true
    @animate {top: @defaults.top, duration: duration}, callback

  slideFadeUp: (duration, callback) ->
    cb = =>
      @element.visible = false
      callback() if callback
    @animate {top: '-' + @get('height'), opacity: 0, duration: duration}, cb

  slideFadeDown: (duration, callback) ->
    @element.visible = true
    @animate {top: @defaults.top, opacity: 1, duration: duration}, callback


Tiger.Element.include FX


Tiger.FX = FX
module?.exports = FX