# Tiger 0.1.4 by Charles Phillips <charles@doublerebel.com>
# A library enhancing Titanium apps with Spine's MVC architecture
# Uses CoffeeScript's inheritance, and adds jQuery-like chainability
# Add tiger.db for persistent storage
# MIT Licensed, Copyright 2011 - 2013 Double Rebel


Spine = @Spine or require './spine'


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
    return unless Tiger.Log.trace
    level = args[0] in logLevels and args.shift()
    level = @logLevel or level or 'info'
    prefix = @logPrefix and @logPrefix + ' ' or ''
    for obj in args
      if typeof obj is 'string' then Ti.API.log level, prefix + obj
      else Ti.API.log level, prefix + "#{key}: #{val}" for key, val of obj
    @

  stackTrace: (err = new Error) ->
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
    #contentType: 'application/x-www-form-urlencoded; charset=UTF-8'
    contentType: 'application/json'
    enableKeepAlive: false
    # validatesSecureCertificate
    # withCredentials
    timeout: 10000

    # Ti API Options
    async: true
    autoEncodeUrl: true

    # Callbacks
    success: ->
    error: ->
    beforeSend: null
    complete: ->
    onreadystatechanged: null

  @encode: (string) ->
    Ti.Network.encodeURIComponent string

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
      unless xhr.statusText
        if xhr.readyState is xhr.OPENED then error = 'No response from server'
        else error = 'Unknown error'
      options.error xhr, xhr.statusText, error
      options.complete xhr, xhr.statusText
    xhr.onload = ->
      try
        response = xhr.responseXML
      catch e
        response = xhr.responseText
      options.success response, xhr.statusText, xhr
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
      options.url += @constructor.params options.data

    if Ti.Network.networkType is Ti.Network.NETWORK_NONE
      @debug "No network available.  Cannot open connection to #{options.url}"
      return xhr

    xhr.open options.method, options.url
    xhr.file = options.file if options.file
    if options.headers
      xhr.setRequestHeader name, header for name, header of options.headers

    options.beforeSend xhr, options if options.beforeSend
    if options.data and options.method is 'POST' or options.method is 'PUT'
      @debug "Sending #{options.data} ..."
      xhr.setRequestHeader 'Content-Type', options.contentType
      xhr.send options.data
    else xhr.send()
    xhr


class Controller extends Module
  @include Spine.Events
  @include Log

  eventSplitter: /^(\w+)\s*(.*)$/

  constructor: (@options = {}) ->
    @[key] = val for key, val of @options
    @_map = {}
    @_events = {}

    @elements or= @constructor.elements
    @refreshElements() if @elements

    @events or= @constructor.events
    @delegateEvents() if @events

    @map or= @constructor.map
    @bindSynced() if @map

  refreshElements: ->
    return unless @view
    for el in @elements
      @[el] = @view[el]
    @

  mapSelector: (selector) ->
    return el if el = @_map[selector]
    if '.' in selector
      selectors = selector.split '.'
      sel = selectors.shift()
      el = @[sel] or @[sel] = @view[sel]
      el = el[s] for s in selectors
    else el = @[selector] or @[selector] = @view[selector]
    @_map[selector] = el

  delegateEvents: ->
    for key, methodName of @events
      @_events[key] = @proxy @[methodName]
      match         = key.match @eventSplitter
      eventName     = match[1]
      selector      = match[2]

      @debug "Binding #{selector} #{eventName}..."
      if selector is '' then @view.tiBind eventName, @_events[key]
      else
        el = @mapSelector selector
        el.tiBind eventName, @_events[key]
    @

  release: (key) =>
    unless key
      @trigger 'release'
      @view.remove()
      @unbind()

    else
      match     = key.match @eventSplitter
      eventName = match[1]
      selector  = match[2]

      el = if selector then (@mapSelector selector) else @view
      el.tiUnbind eventName, @_events[key]

  bindSynced: ->
    for field, selector of @map
      @debug "Binding #{field} to #{selector}..."
      do (field, self = @) ->
        el = self.mapSelector selector
        el.change((e) -> self.store[field] = e.value) if el
    @

  loadSynced: ->
    for field, selector of @map
      if '.' in selector
        selectors = selector.split '.'
        prop = "#{selectors.pop()}"
        selector = selectors.join()
      else prop = 'value'
      el = @_map[selector] or @mapSelector selector
      value = @store[field]
      value or= '' if prop is 'value'
      props = {}
      props[prop] = value
      el.set props
    @

  delay: (timeout = 0, func) ->
    setTimeout @proxy(func), timeout


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

  tiTrigger: ->
    @element.fireEvent.apply(@element, arguments)
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

Tiger.version    = '0.1.4'
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
