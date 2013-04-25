Tiger = @Tiger or require('tiger')
Model = Tiger.Model

{Pipeliner}  = require '/lib/icedlib'


Ajax =
  getURL: (object) ->
    object and object.url?() or object.url

  enabled: true
  
  disable: (callback) ->
    if @enabled
      @enabled = false
      try
        do callback
      catch e
        throw e
      finally
        @enabled = true
    else
      do callback

  max: 100
  throttle: 0

  queue: (request) ->
    @pipeliner or= new Pipeliner @max, @throttle
    return @pipeliner.queue unless request
    await @pipeliner.waitInQueue defer()
    request @pipeliner.defer()

  clearQueue: ->
    @pipeliner.queue = []
    @pipeliner.n_out = 0

class Base
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}

  queue: Ajax.queue

  ajax: (params, defaults) ->
    new Tiger.Ajax @ajaxSettings(params, defaults)

  ajaxQueue: (params, defaults) ->
    xhr = null
    rv  = new iced.Rendezvous
    
    settings     = @ajaxSettings(params, defaults)
    defersuccess = settings.success
    defererror   = settings.error
    
    settings.success = rv.id('success').defer data, statusText, xhr
    settings.error   = rv.id('error').defer xhr, statusText, error
    
    request = (next) ->
      xhr = new Tiger.Ajax(settings)
      await rv.wait defer status
      switch status
        when 'success' then defersuccess data, statusText, xhr
        when 'error' then defererror xhr, statusText, error
      next()

    request.abort = (statusText) ->
      return xhr.abort(statusText) if xhr
      index = @queue().indexOf(request)
      @queue().splice(index, 1) if index > -1
      Ajax.pipeliner.n_out-- if Ajax.pipeliner

      # deferred.rejectWith(
      #   settings.context or settings,
      #   [xhr, statusText, '']
      # )
      request

    return request unless Ajax.enabled
    @queue request
    request

  ajaxSettings: (params, defaults) ->
    Tiger.extend({}, @defaults, defaults, params)

class Collection extends Base
  constructor: (@model) ->

  find: (id, params) ->
    record = new @model(id: id)
    @ajaxQueue params,
      type: 'GET',
      url:  Ajax.getURL(record)
      success: @recordsResponse
      error: @failResponse

  all: (params) ->
    @ajaxQueue params,
      type: 'GET',
      url:  Ajax.getURL(@model)
      success: @recordsResponse
      error: @failResponse

  fetch: (params = {}, options = {}) ->
    if id = params.id
      delete params.id
      @find(id, params).done (record) =>
        @model.refresh(record, options)
    else
      @all(params).done (records) =>
        @model.refresh(records, options)

  # Private

  recordsResponse: (data, status, xhr) =>
    @model.trigger('ajaxSuccess', null, status, xhr)

  failResponse: (xhr, statusText, error) =>
    @model.trigger('ajaxError', null, xhr, statusText, error)

class Singleton extends Base
  constructor: (@record) ->
    @model = @record.constructor

  reload: (params, options) ->
    @ajaxQueue params,
      type: 'GET'
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  create: (params, options) ->
    @ajaxQueue params,
      type: 'POST'
      data: JSON.stringify(@record)
      url:  Ajax.getURL(@model)
      success: @recordResponse(options)
      error: @failResponse(options)

  update: (params, options) ->
    @ajaxQueue params,
      type: 'PUT'
      data: JSON.stringify(@record)
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  destroy: (params, options) ->
    @ajaxQueue params,
      type: 'DELETE'
      url:  Ajax.getURL(@record)
      success: @recordResponse(options)
      error: @failResponse(options)

  # Private

  recordResponse: (options = {}) =>
    (data, status, xhr) =>
      if Spine.isBlank(data)
        data = false
      else
        data = @model.fromJSON(data)

      Ajax.disable =>
        if data
          # ID change, need to do some shifting
          if data.id and @record.id isnt data.id
            @record.changeID(data.id)

          # Update with latest data
          @record.updateAttributes(data.attributes())

      @record.trigger('ajaxSuccess', data, status, xhr)
      options.success?.apply(@record) # Deprecated
      options.done?.apply(@record)

  failResponse: (options = {}) =>
    (xhr, statusText, error) =>
      @record.trigger('ajaxError', xhr, statusText, error)
      options.error?.apply(@record) # Deprecated
      options.fail?.apply(@record)

# Ajax endpoint
Model.host = ''

Include =
  ajax: -> new Singleton(this)

  url: (args...) ->
    url = Ajax.getURL(@constructor)
    url += '/' unless url.charAt(url.length - 1) is '/'
    url += Tiger.Ajax.encode(@id)
    args.unshift(url)
    args.join('/')

Extend =
  ajax: -> new Collection(this)

  url: (args...) ->
    args.unshift(@className.toLowerCase() + 's')
    args.unshift(Model.host)
    args.join('/')

Model.Ajax =
  extended: ->
    @fetch @ajaxFetch
    @change @ajaxChange

    @extend Extend
    @include Include

  # Private

  ajaxFetch: ->
    @ajax().fetch(arguments...)

  ajaxChange: (record, type, options = {}) ->
    return if options.ajax is false
    record.ajax()[type](options.ajax, options)

Model.Ajax.Methods =
  extended: ->
    @extend Extend
    @include Include

# Globals
Ajax.defaults           = Base::defaults
Tiger.Ajax.ModelAdapter = Ajax
Tiger.Ajax.Q            = Base
module?.exports         = Ajax