# Tiger 0.0.2 by Charles Phillips <charles@doublerebel.com>
# A library enhancing Titanium apps with Spine's MVC architecture
# Uses CoffeeScript's inheritance, and adds jQuery-like chainability
# Add tiger.db for persistent storage
# MIT Licensed, Copyright 2011, 2012 Double Rebel


Spine  = @Spine or require 'spine'
  

# Utilities

extend = (target, sources...) ->
  target[key] = val for key, val of source for source in sources
  target

makeArray = (args) ->
  Array::slice.call(args, 0)


# Tiger Modules

class Module extends Spine.Class
  @include
    extend: (sources...) ->
      extend @, sources...

Env = {}

logLevels = ['info', 'warn', 'error', 'debug', 'trace']

Log = extend {}, Spine.Log,
  logLevel: false
  
  log: (args...) ->
    return unless @trace
    level = args[0] in logLevels && args.shift()
    level = @logLevel or level or 'info'
    prefix = @logPrefix and @logPrefix + ' ' or ''
    for obj in args
      if typeof obj is 'string' then Ti.API.log level, prefix + obj
      else Ti.API.log level, prefix + "#{key}: #{val}" for key, val of obj
    @

for level in logLevels
  ((level) ->
    Log[level] = (args...) ->
      args.unshift(level)
      Log.log.apply(@, args)
  )(level)


class Controller extends Module
  @include Spine.Events
  @include Log

  constructor: (@options = {}) ->
    @[key] = val for key, val of @options
    
    @elements or= @constructor.elements
    @refreshElements() if @elements
    
    @events or= @constructor.events
    @delegateEvents() if @events

    @map or= @constructor.map
    @bindSynced() if @map
    
  delegateEvents: ->
    for key, methodName of @events
      method     = @proxy @[methodName]
      match      = key.match /^(\w+)\s*(.*)$/
      eventName  = match[1]
      selector   = match[2]
      
      @debug "Binding #{selector} #{eventName}..."
      if selector is '' then @el.tiBind eventName, method
      else if '.' in selector
        selectors = selector.split '.'
        sel = selectors.shift()
        el = @[sel] or @view[sel]
        el = el[s] for s in selectors
        el.tiBind eventName, method
      else
        @[selector] or= @view[selector]
        @[selector].tiBind eventName, method
    @

  refreshElements: ->
    return unless @view
    for el in @elements
      @[el] = @view[el]
  
  bindSynced: ->
    for key, selector of @map
      @debug "Binding #{key} to #{selector}..."
      ((key, selector, self) ->
        self[selector] or= self.view[selector]
        self[selector].change((e) -> self.store[key] = e.value)
      )(key, selector, @)
    @

  loadSynced: ->
    for key, selector of @map
      @[selector].set value: @store[key] or ''
    @
  
  delay: (func, timeout) ->
    setTimeout @proxy(func), (timeout || 0)


# Tiger View Element Event Wrapper
eventList = [
  'return'
  'click'
  'dblclick'
  'longpress'
  'swipe'
  'touchstart'
  'touchmove'
  'touchcancel'
  'touchend'
  'singletap'
  'twofingertap'
  'pinch'
  'change'
  # 'blur'
  # 'focus'
  'open'
  'close'
  'postlayout'
  # 'show',
  # 'hide',
]
eventWraps = {}

for event in eventList
  ((event) ->
    eventWraps[event] = (fn) ->
      if not fn then @element.fireEvent(event)
      else @tiBind(event, fn)
      @
  )(event)

for event in ['blur', 'focus']
  ((event) ->
    eventWraps[event] = (fn) ->
      if not fn then @element[event]()
      else @tiBind(event, fn)
      @
  )(event)



capitalize = (string) -> string.charAt(0).toUpperCase() + string.slice(1)


class Element extends Module
  @include eventWraps
  
  constructor: (props = {}) ->
    props = Tiger.extend {}, @defaults or {}, props
    @element = Ti.UI['create' + @elementName](props)
  
  add: (el) ->
    @element.add(el.element || el)
    @
  
  set: (props) ->
    for key, val of props
      cKey = capitalize(key)
      if 'set' + cKey of @
        @['set' + cKey](val)
      else @element[key] = val
    @
  
  get: (prop) ->
    cProp = capitalize(prop)
    return @[prop] || @['get' + cProp] && @['get' + cProp]() || @element[prop]
  
  hide: ->
    @element.hide()
    @element.visible = false
    @
  
  show: ->
    @element.show()
    @element.visible = true
    @
  
  tiBind: (event, fn) ->
    @element.addEventListener(event, fn)
    @
  
  tiUnbind: (event, fn) ->
    @element.removeEventListener(event, fn)
    @
  
  tiTrigger: (event) ->
    @element.fireEvent(event)
    @
  
  remove: (el) ->
    @element.remove(el.element || el)
    @

  animate: (options, callback) ->
    animation = Titanium.UI.createAnimation(options)
    if callback then animation.addEventListener 'complete', callback
    @element.animate animation
    @

# Globals

Tiger = @Tiger   = {}
module?.exports  = Tiger

Tiger.version    = '0.0.2'
Tiger.extend     = extend
Tiger.makeArray  = makeArray
Tiger.isArray    = Spine.isArray
Tiger.Class      = Module
Tiger.Controller = Controller
Tiger.Element    = Element
Tiger.Env        = Env
Tiger.Events     = Spine.Events
Tiger.Log        = Log
Tiger.Model      = Spine.Model
