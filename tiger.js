/*
** Tiger 0.0.1 by Charles Phillips <charles@doublerebel.com>
** A library enhancing Titanium apps with Spine's MVC architecture
** Includes inheritance, super constructor, and chainability
** Add spine.tigerdb.js for persistent storage
** MIT Licensed, Copyright 2011 Double Rebel
*/

(function(){
    
    // Utility functions
    function getGlobal() {
        return (function() {
          return this;
          }).call(null);
    }
    var listProps = function(obj) {
        for (var key in obj) Ti.API.debug(key);
    };
  
    // Tiger
    
    var Tiger;
    if (typeof exports !== "undefined") {
        Tiger = exports;
    } else {
        Tiger = this.Tiger = {};
    }
    
    Tiger.version = "0.0.1";
    
    var TiExtend = Tiger.extend = function(target, source) {
        if (source) for (var key in source) target[key] = source[key];
        return target;
    };
    // Haven't been able to get a working deep extend yet... Probably needs to be flattened somehow
    //var TiExtend = Tiger.extend = function() {
    //    var deep,
    //        i = 1,
    //        l = arguments.length,
    //        target = (deep = arguments[0]) === true ? arguments[1] : deep,
    //        source;
    //
    //    if (deep === true) {
    //        Ti.API.debug('deeptrue');
    //        i++;
    //    }
    //
    //    if ( typeof target !== "object" && typeof target !== 'function' )
    //        target = {};
    //
    //    for ( ; i < l; i++ ) {
    //        if ( (source = arguments[ i ]) !== null && source !== undefined) {
    //            for ( var key in source ) {
    //                var dest = target[ key ],
    //                    copy = source[ key ];
    //                    
    //                // Prevent never-ending loop
    //                if ( target === copy ) continue;
    //                
    //                if ( deep && copy && typeof copy === "object" ) {
    //                    target[ key ] = arguments.callee(
    //                        deep,
    //                        // Never move original objects, clone them
    //                        dest || ( copy.length != null ? [] : {} ),
    //                        copy
    //                    );
    //                } else target[ key ] = copy;
    //            }
    //        }
    //    }
    //    return target;
    //};
    
    // Add ability to run super constructor from Spine Classes
    Spine.Class.extend({
        _super: function(fn) {
            var self = this;
            return function(args) {
                //return self.__proto__[fn].call(self, args);
                return self.parent[fn].call(self, args);
            }
        }
    });
    
    Tiger = TiExtend(Tiger, {
        globals: [],
        globalStore: {},
        save: function() {
            for (var i = 0, l = Tiger.globals.length, global = getGlobal(); i < l; i++) {
                Ti.App[ Tiger.globals[i] ] = global[ Tiger.globals[i] ];
            }
            Ti.App.Tiger = this;
        },
        restore: function() {
            for (var i = 0, l = Tiger.globals.length, global = getGlobal(); i < l; i++) {
                global[ Tiger.globals[i] ] = Ti.App[ Tiger.globals[i] ];
            }
            global.Tiger = this;
        },
        init: function() {
            this.restore();
            var g = getGlobal(),
                winname = 'win' + Ti.UI.currentWindow.url.split('.')[0].replace(/^\w/, function($0) { return $0.toUpperCase(); });
            g.win = g[winname];
        },
        Obj: Spine.Class.create()
    });
    
    // Base Tiger Object
    var TiObj = Tiger.Obj;
    
    // Base Tiger View Element
    Tiger.Element = Spine.Class.create();
    Tiger.Element.include({
        add: function(el) {
            this.element.add(el.element || el);
            return this;
        },
        set: function(props) {
            for (var key in props) {
                if ('set' + key in this)
                    this['set' + key]( props[key] );
                else this.element[key] = props[key];
            }
            return this;
        },
        get: function(prop) {
            return this[prop] || this['get' + prop] && this['get' + prop]() || this.element[prop]
        },
        hide: function() {
            this.element.hide();
            this.element.visible = false;
            return this;
        },
        show: function() {
            this.element.show();
            this.element.visible = true;
            return this;
        },
        tiBind: function(event, fn) {
            this.element.addEventListener(event, fn)
            return this;
        },
        tiUnbind: function(event, fn) {
            this.element.removeEventListener(event, fn);
            return this;
        },
        tiTrigger: function(event) {
            this.element.fireEvent(event);
            return this;
        },
        remove: function(el) {
            this.element.remove(el.element || el);
            return this;
        }
    });
    
    // Tiger View Element Event Wrapper
    var eventList = [
        'click',
        'touchStart',
        'touchEnd',
        'focus',
        'blur',
        'open',
        'close',
        //'show',
        //'hide',
        'change'
    ];
    for (var i = 0, l = eventList.length, eventWraps = {}; i < l; i++) {
        (function(i) {
            var event = eventList[i];
            eventWraps[event] = function(fn) {
                if (!fn) this.element.fireEvent(event);
                else this.tiBind(event, fn);
                return this;
            };
        })(i);
    }
    Tiger.Element.include(eventWraps);
    var TiElement = Tiger.Element;
  
    // Wrap all Titanium View Elements
    var elements = [
        "Window",
        "View",
        "ImageView",
        "ScrollView",
        "TableView",
        "TableViewRow",
        "Label",
        "TextField",
        "Button",
        "Switch"
    ];
    for (var i = 0, l = elements.length, global = getGlobal(); i < l; i++) {
        var element = elements[i];
        
        global['Ti' + element] = Tiger[element] = TiElement.create({
            elementName: element,
            init: function(props) {
                props || (props = {});
                this.element = Ti.UI['create' + this.elementName](props);
            }
        });
    }
    
    // Extend individual elements for special cases
    Tiger.Window.extend({
        _init: Tiger.Window.init,
        init: function(props) {
            var win = this._init(props);
            win.tiBind('android:back', function() {
                for (var w = win.element, i = w.children.length - 1; i > -1; i--)
                    w.remove(w.children[i]);
                setTimeout(function() { w.close(); }, 70);
            });
            return win;
        }
    });
    
    Tiger.TableView.include({
        appendRow: function(el) {
            this.element.appendRow(el.element || el);
            return this;
        },
        setdata: function(rows) {
            for (var i = 0, l = rows.length, nativeRows = []; i < l; i++)
                nativeRows.push(rows[i].element || rows[i]);
            this.element.setData(nativeRows);
            return this;
        }
    });
    
    Tiger.TableViewRow.extend({
        _init: Tiger.TableViewRow.init,
        init: function(props) {
            props = Tiger.extend({
                className: 'GUID' + Spine.guid().slice(-12)
            }, props);
            return this._init(props);
        }
    });
    
    //Ti.API.debug(Tiger);
    
    var eventSplitter = /^(\w+)\s*(.*)$/;

    var TiController = Tiger.Controller = Spine.Class.create({
        initialize: function(options){
            this.options = options;
            
            for (var key in this.options)
                this[key] = this.options[key];
            
            if ( !this.events ) this.events = this.parent.events;
            
            if (this.events) this.delegateEvents();
            if (this.proxied) this.proxyAll.apply(this, this.proxied);
        },
        delegateEvents: function(){
            for (var key in this.events) {
                var methodName = this.events[key],
                    method     = this.proxy(this[methodName]),
                    match      = key.match(eventSplitter),
                    eventName  = match[1], selector = match[2];
                
                if (selector == '') this.el.tiBind(eventName, method);
                else this[selector].tiBind(eventName, method);
            }
            return this;
        },
        bindSynced: function(namespace) {
            namespace || (namespace = getGlobal());
            for (var key in this.map) {
                (function(key, self) {
                    self[key] = namespace[key]
                        .change(self.proxy(function(e) {
                            self.store[self.map[key]] = e.value;
                        }));
                })(key, this);
            }
            return this;
        },
        loadSynced: function() {
            for (var key in this.map) {
                var val = this.store[this.map[key]];
                if (String(val) === 'undefined') val = '';
                this[key].set({ value: val });
            }
            return this;
        },
        delay: function(func, timeout){
            return setTimeout(this.proxy(func), timeout || 0);
        }
    }).include(Spine.Events)
      .include(Spine.Log);
    
})();
