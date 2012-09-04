(function() {
  var Controller, Element, Env, Log, Module, Spine, Tiger, capitalize, event, eventList, eventWraps, extend, level, logLevels, makeArray, _fn, _fn2, _fn3, _i, _j, _k, _len, _len2, _len3, _ref,
    __slice = Array.prototype.slice,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Spine = this.Spine || require('spine');

  extend = function() {
    var key, source, sources, target, val, _i, _len;
    target = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      for (key in source) {
        val = source[key];
        target[key] = val;
      }
    }
    return target;
  };

  makeArray = function(args) {
    return Array.prototype.slice.call(args, 0);
  };

  Module = (function(_super) {

    __extends(Module, _super);

    function Module() {
      Module.__super__.constructor.apply(this, arguments);
    }

    Module.include({
      extend: function() {
        var sources;
        sources = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return extend.apply(null, [this].concat(__slice.call(sources)));
      }
    });

    return Module;

  })(Spine.Class);

  Env = {};

  logLevels = ['info', 'warn', 'error', 'debug', 'trace'];

  Log = extend({}, Spine.Log, {
    logLevel: false,
    log: function() {
      var args, key, level, obj, prefix, val, _i, _len, _ref;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!this.trace) return;
      level = (_ref = args[0], __indexOf.call(logLevels, _ref) >= 0) && args.shift();
      level = this.logLevel || level || 'info';
      prefix = this.logPrefix && this.logPrefix + ' ' || '';
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        obj = args[_i];
        if (typeof obj === 'string') {
          Ti.API.log(level, prefix + obj);
        } else {
          for (key in obj) {
            val = obj[key];
            Ti.API.log(level, prefix + ("" + key + ": " + val));
          }
        }
      }
      return this;
    }
  });

  _fn = function(level) {
    return Log[level] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      args.unshift(level);
      return Log.log.apply(this, args);
    };
  };
  for (_i = 0, _len = logLevels.length; _i < _len; _i++) {
    level = logLevels[_i];
    _fn(level);
  }

  Controller = (function(_super) {

    __extends(Controller, _super);

    Controller.include(Spine.Events);

    Controller.include(Log);

    function Controller(options) {
      var key, val, _ref;
      this.options = options != null ? options : {};
      _ref = this.options;
      for (key in _ref) {
        val = _ref[key];
        this[key] = val;
      }
      this.elements || (this.elements = this.constructor.elements);
      if (this.elements) this.refreshElements();
      this.events || (this.events = this.constructor.events);
      if (this.events) this.delegateEvents();
      this.map || (this.map = this.constructor.map);
      if (this.map) this.bindSynced();
    }

    Controller.prototype.delegateEvents = function() {
      var el, eventName, key, match, method, methodName, s, sel, selector, selectors, _j, _len2, _ref;
      _ref = this.events;
      for (key in _ref) {
        methodName = _ref[key];
        method = this.proxy(this[methodName]);
        match = key.match(/^(\w+)\s*(.*)$/);
        eventName = match[1];
        selector = match[2];
        this.debug("Binding " + selector + " " + eventName + "...");
        if (selector === '') {
          this.el.tiBind(eventName, method);
        } else if (__indexOf.call(selector, '.') >= 0) {
          selectors = selector.split('.');
          sel = selectors.shift();
          el = this[sel] || this.view[sel];
          for (_j = 0, _len2 = selectors.length; _j < _len2; _j++) {
            s = selectors[_j];
            el = el[s];
          }
          el.tiBind(eventName, method);
        } else {
          this[selector] || (this[selector] = this.view[selector]);
          this[selector].tiBind(eventName, method);
        }
      }
      return this;
    };

    Controller.prototype.refreshElements = function() {
      var el, _j, _len2, _ref, _results;
      if (!this.view) return;
      _ref = this.elements;
      _results = [];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        el = _ref[_j];
        _results.push(this[el] = this.view[el]);
      }
      return _results;
    };

    Controller.prototype.bindSynced = function() {
      var key, selector, _fn2, _ref;
      _ref = this.map;
      _fn2 = function(key, selector, self) {
        self[selector] || (self[selector] = self.view[selector]);
        return self[selector].change(function(e) {
          return self.store[key] = e.value;
        });
      };
      for (key in _ref) {
        selector = _ref[key];
        this.debug("Binding " + key + " to " + selector + "...");
        _fn2(key, selector, this);
      }
      return this;
    };

    Controller.prototype.loadSynced = function() {
      var key, selector, _ref;
      _ref = this.map;
      for (key in _ref) {
        selector = _ref[key];
        this[selector].set({
          value: this.store[key] || ''
        });
      }
      return this;
    };

    Controller.prototype.delay = function(func, timeout) {
      return setTimeout(this.proxy(func), timeout || 0);
    };

    return Controller;

  })(Module);

  eventList = ['return', 'click', 'dblclick', 'longpress', 'swipe', 'touchstart', 'touchmove', 'touchcancel', 'touchend', 'singletap', 'twofingertap', 'pinch', 'change', 'open', 'close', 'postlayout'];

  eventWraps = {};

  _fn2 = function(event) {
    return eventWraps[event] = function(fn) {
      if (!fn) {
        this.element.fireEvent(event);
      } else {
        this.tiBind(event, fn);
      }
      return this;
    };
  };
  for (_j = 0, _len2 = eventList.length; _j < _len2; _j++) {
    event = eventList[_j];
    _fn2(event);
  }

  _ref = ['blur', 'focus'];
  _fn3 = function(event) {
    return eventWraps[event] = function(fn) {
      if (!fn) {
        this.element[event]();
      } else {
        this.tiBind(event, fn);
      }
      return this;
    };
  };
  for (_k = 0, _len3 = _ref.length; _k < _len3; _k++) {
    event = _ref[_k];
    _fn3(event);
  }

  capitalize = function(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  };

  Element = (function(_super) {

    __extends(Element, _super);

    Element.include(eventWraps);

    function Element(props) {
      if (props == null) props = {};
      props = Tiger.extend({}, this.defaults || {}, props);
      this.element = Ti.UI['create' + this.elementName](props);
    }

    Element.prototype.add = function(el) {
      this.element.add(el.element || el);
      return this;
    };

    Element.prototype.set = function(props) {
      var cKey, key, val;
      for (key in props) {
        val = props[key];
        cKey = capitalize(key);
        if ('set' + cKey in this) {
          this['set' + cKey](val);
        } else {
          this.element[key] = val;
        }
      }
      return this;
    };

    Element.prototype.get = function(prop) {
      var cProp;
      cProp = capitalize(prop);
      return this[prop] || this['get' + cProp] && this['get' + cProp]() || this.element[prop];
    };

    Element.prototype.hide = function() {
      this.element.hide();
      this.element.visible = false;
      return this;
    };

    Element.prototype.show = function() {
      this.element.show();
      this.element.visible = true;
      return this;
    };

    Element.prototype.tiBind = function(event, fn) {
      this.element.addEventListener(event, fn);
      return this;
    };

    Element.prototype.tiUnbind = function(event, fn) {
      this.element.removeEventListener(event, fn);
      return this;
    };

    Element.prototype.tiTrigger = function(event) {
      this.element.fireEvent(event);
      return this;
    };

    Element.prototype.remove = function(el) {
      this.element.remove(el.element || el);
      return this;
    };

    Element.prototype.animate = function(options, callback) {
      var animation;
      animation = Titanium.UI.createAnimation(options);
      if (callback) animation.addEventListener('complete', callback);
      this.element.animate(animation);
      return this;
    };

    return Element;

  })(Module);

  Tiger = this.Tiger = {};

  if (typeof module !== "undefined" && module !== null) module.exports = Tiger;

  Tiger.version = '0.0.2';

  Tiger.extend = extend;

  Tiger.makeArray = makeArray;

  Tiger.isArray = Spine.isArray;

  Tiger.Class = Module;

  Tiger.Controller = Controller;

  Tiger.Element = Element;

  Tiger.Env = Env;

  Tiger.Events = Spine.Events;

  Tiger.Log = Log;

  Tiger.Model = Spine.Model;

}).call(this);
