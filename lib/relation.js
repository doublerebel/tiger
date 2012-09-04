(function() {
  var Instance, M2MCollection, O2MCollection, Singleton, Tiger, isArray, singularize, underscore,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Tiger = this.Tiger || require('tiger');

  isArray = Tiger.isArray;

  O2MCollection = (function(_super) {

    __extends(O2MCollection, _super);

    function O2MCollection(options) {
      var key, value;
      if (options == null) options = {};
      for (key in options) {
        value = options[key];
        this[key] = value;
      }
    }

    O2MCollection.prototype.add = function(item, save) {
      var i, _i, _len, _results;
      if (save == null) save = true;
      if (isArray(item)) {
        _results = [];
        for (_i = 0, _len = item.length; _i < _len; _i++) {
          i = item[_i];
          _results.push(this.add(i, false));
        }
        return _results;
      } else {
        if (!(item instanceof this.model)) item = this.model.find(item);
        this.record[this.lkey].push(item[this.fkey]);
        if (save) return this.record.save();
      }
    };

    O2MCollection.prototype.remove = function(item) {
      if (!(item instanceof this.model)) item = this.model.find(item);
      return this.record[this.lkey].splice(this.record[this.lkey].indexOf(item[this.fkey]));
    };

    O2MCollection.prototype.all = function() {
      var _this = this;
      return this.model.select(function(record) {
        var _ref;
        return _ref = record[_this.fkey], __indexOf.call(_this.record[_this.lkey], _ref) >= 0;
      });
    };

    O2MCollection.prototype.first = function() {
      return this.all()[0];
    };

    O2MCollection.prototype.last = function() {
      var values;
      values = this.all();
      return values[values.length(-1)];
    };

    O2MCollection.prototype.find = function(id) {
      return __indexOf.call(this.record[this.lkey], id) >= 0 && this.model.find(id || (function() {
        throw 'Unknown record';
      })());
    };

    O2MCollection.prototype.create = function(record) {
      return this.add(this.model.create(record));
    };

    return O2MCollection;

  })(Tiger.Class);

  M2MCollection = (function(_super) {

    __extends(M2MCollection, _super);

    function M2MCollection(options) {
      var key, value;
      if (options == null) options = {};
      for (key in options) {
        value = options[key];
        this[key] = value;
      }
    }

    M2MCollection.prototype.add = function(item) {
      var hub, i, _i, _len, _results;
      if (isArray(item)) {
        _results = [];
        for (_i = 0, _len = item.length; _i < _len; _i++) {
          i = item[_i];
          _results.push(this.add(i));
        }
        return _results;
      } else {
        if (!(item instanceof this.model)) item = this.model.find(item);
        hub = new this.Hub();
        if (this.left_to_right) {
          hub["" + this.rev_name + "_id"] = this.record.id;
          hub["" + this.name + "_id"] = item.id;
        } else {
          hub["" + this.rev_name + "_id"] = item.id;
          hub["" + this.name + "_id"] = this.record.id;
        }
        return hub.save();
      }
    };

    M2MCollection.prototype.remove = function(item) {
      var i, _i, _len, _ref, _results,
        _this = this;
      _ref = this.Hub.select(function(item) {
        return _this.associated(item);
      });
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        _results.push(i.destroy());
      }
      return _results;
    };

    M2MCollection.prototype._link = function(items) {
      var _this = this;
      return items.map(function(item) {
        if (_this.left_to_right) {
          return _this.model.find(item["" + _this.name + "_id"]);
        } else {
          return _this.model.find(item["" + _this.rev_name + "_id"]);
        }
      });
    };

    M2MCollection.prototype.all = function() {
      var _this = this;
      return this._link(this.Hub.select(function(item) {
        return _this.associated(item);
      }));
    };

    M2MCollection.prototype.first = function() {
      return this.all()[0];
    };

    M2MCollection.prototype.last = function() {
      var values;
      values = this.all();
      return values[values.length(-1)];
    };

    M2MCollection.prototype.find = function(id) {
      var records,
        _this = this;
      records = this.Hub.select(function(rec) {
        return _this.associated(rec, id);
      });
      if (!records[0]) throw 'Unknown record';
      return this._link(records)[0];
    };

    M2MCollection.prototype.create = function(record) {
      return this.add(this.model.create(record));
    };

    M2MCollection.prototype.associated = function(record, id) {
      if (this.left_to_right) {
        if (record["" + this.rev_name + "_id"] !== this.record.id) return false;
        if (id) return record["" + this.rev_name + "_id"] === id;
      } else {
        if (record["" + this.name + "_id"] !== this.record.id) return false;
        if (id) return record["" + this.name + "_id"] === id;
      }
      return true;
    };

    return M2MCollection;

  })(Tiger.Class);

  Instance = (function(_super) {

    __extends(Instance, _super);

    function Instance(options) {
      var key, value;
      if (options == null) options = {};
      for (key in options) {
        value = options[key];
        this[key] = value;
      }
    }

    Instance.prototype.exists = function() {
      return this.record[this.fkey] && this.model.exists(this.record[this.fkey]);
    };

    Instance.prototype.update = function(value) {
      if (!(value instanceof this.model)) value = new this.model(value);
      if (value.isNew()) value.save();
      return this.record[this.fkey] = value && value.id;
    };

    return Instance;

  })(Tiger.Class);

  Singleton = (function(_super) {

    __extends(Singleton, _super);

    function Singleton(options) {
      var key, value;
      if (options == null) options = {};
      for (key in options) {
        value = options[key];
        this[key] = value;
      }
    }

    Singleton.prototype.find = function() {
      return this.record.id && this.model.findByAttribute(this.fkey, this.record.id);
    };

    Singleton.prototype.update = function(value) {
      if (!(value instanceof this.model)) value = this.model.fromJSON(value);
      value[this.fkey] = this.record.id;
      return value.save();
    };

    return Singleton;

  })(Tiger.Class);

  singularize = function(str) {
    return str.replace(/s$/, '');
  };

  underscore = function(str) {
    return str.replace(/::/g, '/').replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2').replace(/([a-z\d])([A-Z])/g, '$1_$2').replace(/-/g, '_').toLowerCase();
  };

  Tiger.Model.extend({
    __filter: function(args, revert) {
      if (revert == null) revert = false;
      return function(rec) {
        var key, q, value;
        q = !!revert;
        for (key in args) {
          value = args[key];
          if (rec[key] !== value) return q;
        }
        return !q;
      };
    },
    filter: function(args) {
      return this.select(this.__filter(args));
    },
    exclude: function(args) {
      return this.select(this.__filter(args, true));
    },
    oneToMany: function(model, name, fkey) {
      var association, lkey;
      if (typeof model === 'string') model = require(model);
      if (name == null) {
        name = model.className.toLowerCase();
        name = singularize(underscore(name));
      }
      lkey = "" + name + "_ids";
      if (__indexOf.call(this.attributes, lkey) < 0) this.attributes.push(lkey);
      if (fkey == null) fkey = 'id';
      association = function(record, model) {
        if (!record[lkey]) record[lkey] = [];
        return new O2MCollection({
          lkey: lkey,
          fkey: fkey,
          record: record,
          model: model
        });
      };
      return this.prototype["" + name + "s"] = function(value) {
        return association(this, model);
      };
    },
    hasMany: function(name, model, fkey) {
      var association;
      if (fkey == null) fkey = "" + (underscore(this.className)) + "_id";
      association = function(record) {
        var q;
        if (typeof model === 'string') model = require(model);
        q = {};
        q[fkey] = record.id;
        return model.filter(q);
      };
      return this.prototype[name] = function(value) {
        if (value != null) association(this).refresh(value);
        return association(this);
      };
    },
    belongsTo: function(name, model, fkey) {
      var association;
      if (fkey == null) fkey = "" + (singularize(name)) + "_id";
      association = function(record) {
        if (typeof model === 'string') model = require(model);
        return new Instance({
          name: name,
          model: model,
          record: record,
          fkey: fkey
        });
      };
      this.prototype[name] = function(value) {
        if (value != null) association(this).update(value);
        return association(this).exists();
      };
      return this.attributes.push(fkey);
    },
    hasOne: function(name, model, fkey) {
      var association;
      if (fkey == null) fkey = "" + (underscore(this.className)) + "_id";
      association = function(record) {
        if (typeof model === 'string') model = require(model);
        return new Singleton({
          name: name,
          model: model,
          record: record,
          fkey: fkey
        });
      };
      return this.prototype[name] = function(value) {
        if (value != null) association(this).update(value);
        return association(this).find();
      };
    },
    foreignKey: function(model, name, rev_name) {
      if (rev_name == null) {
        rev_name = this.className.toLowerCase();
        rev_name = singularize(underscore(rev_name));
        rev_name = "" + rev_name + "s";
      }
      if (typeof model === 'string') model = require(model);
      if (name == null) {
        name = model.className.toLowerCase();
        name = singularize(underscore(name));
      }
      this.belongsTo(name, model);
      return model.hasMany(rev_name, this);
    },
    manyToMany: function(model, name, rev_name) {
      var Hub, association, local, rev_model, tigerDB;
      if (rev_name == null) {
        rev_name = this.className.toLowerCase();
        rev_name = singularize(underscore(rev_name));
        rev_name = "" + rev_name + "s";
      }
      rev_model = this;
      if (typeof model === 'string') model = require(model);
      if (name == null) {
        name = model.className.toLowerCase();
        name = singularize(underscore(name));
      }
      local = typeof model.loadLocal === 'function' || typeof rev_model.loadLocal === 'function';
      tigerDB = typeof model.loadTigerDB === 'function' || typeof rev_model.loadTigerDB === 'function';
      Hub = (function(_super) {

        __extends(Hub, _super);

        function Hub() {
          Hub.__super__.constructor.apply(this, arguments);
        }

        if (local) Hub.extend(Tiger.Model.Local);

        if (tigerDB) Hub.extend(Tiger.Model.TigerDB);

        Hub.configure("_" + rev_name + "_to_" + name, "" + Hub.rev_name + "_id", "" + Hub.name + "_id");

        return Hub;

      })(Tiger.Model);
      if (local || tigerDB) Hub.fetch();
      Hub.foreignKey(rev_model, "" + rev_name);
      Hub.foreignKey(model, "" + name);
      association = function(record, model, left_to_right) {
        return new M2MCollection({
          name: name,
          rev_name: rev_name,
          record: record,
          model: model,
          Hub: Hub,
          left_to_right: left_to_right
        });
      };
      rev_model.prototype["" + name + "s"] = function(value) {
        return association(this, model, true);
      };
      return model.prototype["" + rev_name + "s"] = function(value) {
        return association(this, rev_model, false);
      };
    }
  });

}).call(this);
