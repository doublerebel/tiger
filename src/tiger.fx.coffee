Tiger = require '/lib/tiger'


FX =
  fadeIn: (duration, callback) ->
    @element.visible = true
    @fadeTo 1, duration, callback

  fadeOut: (duration, callback) ->
    @element.visible = false
    @fadeTo 0, duration, callback
  
  fadeTo: (opacity, duration, callback) ->
    @animate {opacity: opacity, duration: duration}, callback

  slideUp: (duration, callback) ->
    @element.visible = false
    @animate {top: '-' + @get('height'), duration: duration}, callback

  slideDown: (duration, callback) ->
    @element.visible = true
    @animate {top: @defaults.top, duration: duration}, callback


Tiger.Element.include FX


Tiger.FX = FX
module?.exports = FX