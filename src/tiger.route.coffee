Tiger = @Tiger or require 'tiger'


namedParam   = /:([\w\d]+)/g
splatParam   = /\*([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g


class Tiger.Route extends Tiger.Class
  @extend Tiger.Events

  @routes: []

  @options:
    trigger: true
    history: false
    backwards: false

  @add: (path, callback) ->
    if (typeof path is 'object' and path not instanceof RegExp)
      @add(key, value) for key, value of path
    else
      @routes.push(new @(path, callback))

  @setup: (options = {}) ->
    @options = Tiger.extend({}, @options, options)
    @history = @options.history
    
    if @history
      class History extends Tiger.Model
        @configure 'History', 'uri'

        @back: ->
          @all().length and @last().destroy()

      History.bind('refresh change', @change)
      @History = History
    
    @change()

  @unbind: ->
    @History.unbind('refresh change', @change) if @history

  @navigate: (args...) ->
    options = {}

    lastArg = args[args.length - 1]
    if typeof lastArg is 'object'
      options = args.pop()
    else if typeof lastArg is 'boolean'
      options.trigger = args.pop()

    options = Tiger.extend({}, @options, options)
    @backwards = options.backwards

    path = args.join('/')
    return if @path is path
    @path = path

    @trigger('navigate', @path)

    @matchRoute(@path, options) if options.trigger

    if @history
      record = new @History uri: @path
      record.save()
    
  # Private

  @getPath: ->
    path = @History.last()?.uri or ''
    if path.substr(0,1) isnt '/'
      path = '/' + path
    path

  @change: (record, method) ->
    if @history then path = @getPath() else return
    return if @path is path
    @backwards = true if method is 'destroy'
    @path = path
    @matchRoute(@path)

  @matchRoute: (path, options) ->
    for route in @routes
      if route.match(path, options)
        @trigger('change', route, path)
        return route

  constructor: (@path, @callback) ->
    @names = []

    if typeof path is 'string'
      namedParam.lastIndex = 0
      while (match = namedParam.exec(path)) != null
        @names.push(match[1])

      splatParam.lastIndex = 0
      while (match = splatParam.exec(path)) != null
        @names.push(match[1])

      path = path.replace(escapeRegExp, '\\$&')
                 .replace(namedParam, '([^\/]*)')
                 .replace(splatParam, '(.*?)')

      @route = new RegExp('^' + path + '$')
    else
      @route = path

  match: (path, options = {}) ->
    match = @route.exec(path)
    return false unless match
    options.match = match
    params = match.slice(1)

    if @names.length
      for param, i in params
        options[@names[i]] = param

    @callback.call(null, options) isnt false

# Coffee-script bug
Tiger.Route.change = Tiger.Route.proxy(Tiger.Route.change)

Tiger.Controller.include
  route: (path, callback) ->
    Tiger.Route.add(path, @proxy(callback))

  routes: (routes) ->
    @route(key, value) for key, value of routes

  navigate: ->
    Tiger.Route.navigate.apply(Tiger.Route, arguments)

  back: ->
    Tiger.Route.History.back() if Tiger.Route.history

module?.exports = Tiger.Route