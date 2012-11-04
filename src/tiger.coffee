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
  stackTraceLimit: 10
  
  log: (args...) ->
    return unless @trace
    level = args[0] in logLevels and args.shift()
    level = @logLevel or level or 'info'
    prefix = @logPrefix and @logPrefix + ' ' or ''
    for obj in args
      if typeof obj is 'string' then Ti.API.log level, prefix + obj
      else Ti.API.log level, prefix + "#{key}: #{val}" for key, val of obj
    @

  stackTrace: ->
    err = new Error
    Error.stackTraceLimit = @stackTraceLimit
    Error.prepareStackTrace = (err, stack) -> stack
    Error.captureStackTrace err, arguments.callee
    for frame in err.stack
      Log.debug "(trace) #{frame.getFileName()}:#{frame.getLineNumber()} - #{frame.getFunctionName()}"

for level in logLevels
  do (level) ->
    Log[level] = (args...) ->
      args.unshift(level)
      Log.log.apply(@, args)


class Ajax extends Module
  @include Log
  logPrefix: '(Ajax)'

  defaults:
    method: 'GET'
    url: null
    data: false
    contentType: 'application/json'
    timeout: 10000

    # Ti API Options
    async: true
    autoEncodeUrl: true

    # Callbacks
    success: null
    error: null
    beforeSend: null
    complete: null
    onreadystatechanged: null
  
  encode: Ti.Network.encodeURIComponent

  @params: (data) ->
    return '' unless data?
    params = ("#{@encode(key)}=#{@encode(val)}" for key, val of data)
    params.join '&'
    
  @get: (o) ->
    o.method = 'GET'
    new @ o
  
  @post: (o) ->
    o.method = 'POST'
    new @ o

  @download: (options) ->
    file = conf.file
    options.onload = (xhr) ->
      return unless xhr.responseData?
      if xhr.responseData.type is 1
        f = Ti.Filesystem.getFile xhr.responseData.nativePath
        file.deleteFile() if file.exists()
        f.move file.nativePath
      else
        file.write xhr.responseData
      options.success file, xhr.statusText, xhr
    new @ options

  constructor: (options = {}) ->
    options = Tiger.extend {}, @defaults, options
    options.method = options.method.toUpperCase()

    @debug "#{options.method} #{options.url} ..."
    xhr = Ti.Network.createHTTPClient
      autoEncodeUrl: options.autoEncodeUrl
      async: options.async
      timeout: options.timeout
     
    xhr.onerror = -> 
      options.error xhr, xhr.statusText
      options.complete xhr, xhr.statusText
    xhr.onload = ->
      options.success (xhr.responseText or xhr.responseXML), xhr.statusText, xhr
      options.complete xhr, xhr.statusText
    _debug = @proxy @debug
    xhr.onreadystatechanged = options.onreadystatechanged or ->
      switch @readyState
        when @OPENED then _debug 'readyState: opened...'
        when @HEADERS_RECEIVED then _debug 'readyState: headers received...'
        when @LOADING then _debug 'readyState: loading...'
        when @DONE then _debug 'readyState: done.'
    xhr.onsendstream = options.onsendstream or (e) =>
      @debug('Upload progress: ' + e.progress)
    
    if options.method is 'GET' and options.data
      if options.url.indexOf('?') isnt -1 then options.url += '&'
      else options.url += '?'
      options.url += @params options.data
  
    xhr.open options.method, options.url
    xhr.file = options.file if options.file
    xhr.setRequestHeader 'Content-Type', options.contentType
    if options.headers
      xhr.setRequestHeader name, header for name, header of options.headers
             
    options.beforeSend xhr, options if options.beforeSend
    if options.data and options.method is 'POST' or options.method is 'PUT'
      @debug "Sending #{options.data} ..."
      xhr.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
      xhr.send options.data
    else xhr.send()
    xhr


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
      do (key, selector, self = @) ->
        self[selector] or= self.view[selector]
        self[selector].change((e) -> self.store[key] = e.value)
    @

  loadSynced: ->
    for key, selector of @map
      @[selector].set value: @store[key] or ''
    @
  
  delay: (func, timeout) ->
    setTimeout @proxy(func), (timeout or 0)


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
  do (event) ->
    eventWraps[event] = (fn) ->
      if not fn then @element.fireEvent(event)
      else @tiBind(event, fn)
      @
  
for event in ['blur', 'focus']
  do (event) ->
    eventWraps[event] = (fn) ->
      if not fn then @element[event]()
      else @tiBind(event, fn)
      @
  


capitalize = (string) -> string.charAt(0).toUpperCase() + string.slice(1)


class Element extends Module
  @include eventWraps
  
  constructor: (props = {}) ->
    props = Tiger.extend {}, @defaults or {}, props
    @element = Ti.UI['create' + @elementName](props)
  
  add: (el) ->
    @element.add(el.element or el)
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
    return @[prop] or @['get' + cProp] and @['get' + cProp]() or @element[prop]
  
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
  
  tiOne: (event, fn) ->
    @tiBind event, ->
      @removeEventListener(event, arguments.callee)
      fn.apply(@, arguments)

  tiTrigger: (event) ->
    @element.fireEvent(event)
    @
  
  remove: (el) ->
    @element.remove(el.element or el)
    @

  step: ->
    if @animations.length
      delete @animation
      @animation = @animations.shift()
      @element.animate @animation
    @
  
  animate: (options, callback) ->
    callbackAndStep = =>
      callback() if callback
      @step()

    animation = Ti.UI.createAnimation(options)
    animation.addEventListener 'complete', callbackAndStep
    # if @animations then @animations.push animation
    # else
    #   @animations = [animation]
    #   @step()
    @animations = [animation]
    @step()


# Globals

Tiger = @Tiger   = {}
module?.exports  = Tiger

Tiger.version    = '0.0.2'
Tiger.extend     = extend
Tiger.makeArray  = makeArray
Tiger.isArray    = Spine.isArray
Tiger.Class      = Module
Tiger.Ajax       = Ajax
Tiger.Controller = Controller
Tiger.Element    = Element
Tiger.Env        = Env
Tiger.Events     = Spine.Events
Tiger.Log        = Log
Tiger.Model      = Spine.Model
