(function() {
  var Tiger, escapeRegExp, namedParam, splatParam,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __slice = Array.prototype.slice;

  Tiger = this.Tiger || require('tiger');

  namedParam = /:([\w\d]+)/g;

  splatParam = /\*([\w\d]+)/g;

  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;

  Tiger.Route = (function(_super) {

    __extends(Route, _super);

    Route.extend(Tiger.Events);

    Route.routes = [];

    Route.options = {
      trigger: true,
      history: false,
      backwards: false
    };

    Route.add = function(path, callback) {
      var key, value, _results;
      if (typeof path === 'object' && !(path instanceof RegExp)) {
        _results = [];
        for (key in path) {
          value = path[key];
          _results.push(this.add(key, value));
        }
        return _results;
      } else {
        return this.routes.push(new this(path, callback));
      }
    };

    Route.setup = function(options) {
      var History;
      if (options == null) options = {};
      this.options = Tiger.extend({}, this.options, options);
      this.history = this.options.history;
      if (this.history) {
        History = (function(_super2) {

          __extends(History, _super2);

          function History() {
            History.__super__.constructor.apply(this, arguments);
          }

          History.configure('History', 'uri');

          History.back = function() {
            return this.all().length && this.last().destroy();
          };

          return History;

        })(Tiger.Model);
        History.bind('refresh change', this.change);
        this.History = History;
      }
      return this.change();
    };

    Route.unbind = function() {
      if (this.history) return this.History.unbind('refresh change', this.change);
    };

    Route.navigate = function() {
      var args, lastArg, options, path, record;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      options = {};
      lastArg = args[args.length - 1];
      if (typeof lastArg === 'object') {
        options = args.pop();
      } else if (typeof lastArg === 'boolean') {
        options.trigger = args.pop();
      }
      options = Tiger.extend({}, this.options, options);
      this.backwards = options.backwards;
      path = args.join('/');
      if (this.path === path) return;
      this.path = path;
      this.trigger('navigate', this.path);
      if (options.trigger) this.matchRoute(this.path, options);
      if (this.history) {
        record = new this.History({
          uri: this.path
        });
        return record.save();
      }
    };

    Route.getPath = function() {
      var path, _ref;
      path = ((_ref = this.History.last()) != null ? _ref.uri : void 0) || '';
      if (path.substr(0, 1) !== '/') path = '/' + path;
      return path;
    };

    Route.change = function(record, method) {
      var path;
      if (this.history) {
        path = this.getPath();
      } else {
        return;
      }
      if (this.path === path) return;
      if (method === 'destroy') this.backwards = true;
      this.path = path;
      return this.matchRoute(this.path);
    };

    Route.matchRoute = function(path, options) {
      var route, _i, _len, _ref;
      _ref = this.routes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        route = _ref[_i];
        if (route.match(path, options)) {
          this.trigger('change', route, path);
          return route;
        }
      }
    };

    function Route(path, callback) {
      var match;
      this.path = path;
      this.callback = callback;
      this.names = [];
      if (typeof path === 'string') {
        namedParam.lastIndex = 0;
        while ((match = namedParam.exec(path)) !== null) {
          this.names.push(match[1]);
        }
        splatParam.lastIndex = 0;
        while ((match = splatParam.exec(path)) !== null) {
          this.names.push(match[1]);
        }
        path = path.replace(escapeRegExp, '\\$&').replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)');
        this.route = new RegExp('^' + path + '$');
      } else {
        this.route = path;
      }
    }

    Route.prototype.match = function(path, options) {
      var i, match, param, params, _len;
      if (options == null) options = {};
      match = this.route.exec(path);
      if (!match) return false;
      options.match = match;
      params = match.slice(1);
      if (this.names.length) {
        for (i = 0, _len = params.length; i < _len; i++) {
          param = params[i];
          options[this.names[i]] = param;
        }
      }
      return this.callback.call(null, options) !== false;
    };

    return Route;

  })(Tiger.Class);

  Tiger.Route.change = Tiger.Route.proxy(Tiger.Route.change);

  Tiger.Controller.include({
    route: function(path, callback) {
      return Tiger.Route.add(path, this.proxy(callback));
    },
    routes: function(routes) {
      var key, value, _results;
      _results = [];
      for (key in routes) {
        value = routes[key];
        _results.push(this.route(key, value));
      }
      return _results;
    },
    navigate: function() {
      return Tiger.Route.navigate.apply(Tiger.Route, arguments);
    },
    back: function() {
      if (Tiger.Route.history) return Tiger.Route.History.back();
    }
  });

  if (typeof module !== "undefined" && module !== null) {
    module.exports = Tiger.Route;
  }

}).call(this);
