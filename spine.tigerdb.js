/* Version b1 Rev. 19 June 2011
 * Version a02 Rev. 15th Oct 2008
 *
 *
 * TigerDB by Charles Phillips <charles@doublerebel.com>
 * Designed for Tiger for Spine on Titanium 0.0.1
 * Persistent storage through Titanium's SQLite DB
 *
 * Based on javascript-client-side-sqlite3-wrapper
 * http://code.google.com/p/javascript-client-side-sqlite3-wrapper/
 *
 * 
 * Tested working on Safari 5525.20.1 (should work in Chrome as well?) 
 * and will not work in Firefox cause Gears interface has not been 
 * implemented. Only INSERT and FIND are working. 
 * 
 * USE AS FOLLOW:
 * To create a new local database and then a table on the client's machine:
 * 
 * 		storage = LocalStorage('DatabaseName')
 * 		storage.createTable('Phonebook','Name','Number')
 * 
 * Note that TABLES MUST START with a CAPITAL letter. When a table is created, 
 * it is automatically mapped as a method/property of the storage that created 
 * it. Hence we can write:
 * 
 * 		storage.Phonebook
 * 
 * To get to that table and perform CRUD operations on it. 
 * 
 * ------ INSERT ------
 * 
 * INSERTS can take two forms.
 * 	
 * 		storage.Phonebook.insert('Girl Next Door','555-000-001')
 * 
 * Or, the second form allows us to stuff a hash (interchangeably an object in
 * Javascript) into the table. We declare an object/hash.
 * 
 * 		person = {}
 * 		person['Name'] = "Girl Next Door"
 * 		person['Number'] = "555-000-001"
 * 		storage.Phonebook.insert(person)
 * 
 * Similarly, we could have also declared the object as:
 * 
 * 		person = { 	Name: "Girl Next Door",
 * 					Number: "555-000-001" 	}
 * 
 * Note: NO ERROR CHECKING has currently been implemented, if you spell the 
 * field names wrong, or give it too many/few parameters, the operation will 
 * fail silently! (In JS, but Titanium will throw an SQLite error)
 * 
 * Sidenote on allowing this "object form" is that it could be possible 
 * to persist arbitrary Javascript objects with the database *without knowing 
 * beforehand* their properties since SQLite can add more columns when needed 
 * on the fly! 
 * 
 * ------ FIND ------
 * 
 * #find takes two forms (and a 1/2!). To retrieve all rows in a table:
 * 
 * 		storage.Phonebook.find()
 * 
 * All SQLite tables have an implicit rowid column which is unique. We can
 * therefore -- like in Rails -- pass #find an array of rowid's:
 * 
 * 		storage.Phonebook.find([1,2,3,4,5])
 * 
 * The more customary approach is to query using one/multiple conditions 
 * (e.g. the WHERE SQL expression). To do this we pass #find a hash.
 * 
 * 		storage.Phonebook.find( { Name:'Girl Next Door',Number:'555' } )
 * 	
 * Here the "contains" clause is implied, as in the field contains the 
 * string (e.g. SQLite's *like* keyword). If the column contains numeric 
 * data, then we would query it like this.
 * 
 * 		storage.Players.find( {Wins:'>10'} )
 * 
 * The conditionals are passed in as strings and plugged into the SQL statement. 
 * There are six million things wrong with doing this. Further TO DO's for 
 * #find include searching DATETIME and possibly pagination (as in return how 
 * many rows per page and how many pages).
 * 
 * ------- RESTORING ON PAGE RELOAD -------
 * 
 * When the page is reloaded, restoring the mapping of the storage to 
 * its tables is achieved by calling:
 * 
 * 		storage.restoreState()
 * 
 * Hence, this statement should almost always be called right after 
 * the storage is instantiated.
 * 
 */

/* ------------ GLOBAL MODS ------------------ */

// Modified from YAHOO.Tools.printf and extended to the whole String constructor 
// to do Ruby-like string subtituitions in the form of:
// "I am #{0} and that is {1}".printf(Math.floor(21.5454),90) -> "I am 21 and that is 90"

String.prototype.printf = function() { 
    for (var i = 0, l = arguments.length, oStr = this; i < l; i++) { 
        var re = new RegExp("\\#\\{" + (i) + "\\}", "g"); 
        oStr = oStr.replace(re, arguments[i]); 
    } 
    return oStr; 
};

// MAIN //

var TigerDB = function(dbName) {
    var db;

    try {
        if (Ti.Database) {
            db = Ti.Database.open(dbName);
        } else Ti.API.debug("No Ti.Database.");
    } catch(err) {
        Ti.API.debug("Couldn't open the database.");
    }

    var mapTable = function(tableName) {
            this[tableName] = Object.create(TigerTable());
            this[tableName].db = db;
            this[tableName].name = tableName;
            Ti.API.debug(this[tableName].name);
        },
        mapTables = function(row) {
        if (row.name.match(/^[A-Z]/))
            mapTable(row.name);
        };

    return {
        mapTable: mapTable,
        executeQuery: function(string, args, callback) {
            Ti.API.debug("SQL: #{0} | #{1}".printf(string, args.join()));
            var resultSet = db.execute(string, args),
                resultArray = [];
            if (resultSet) {
                while (resultSet.isValidRow()) {
                    var row = {};
                    for (var i = 0, l = resultSet.fieldCount; i < l; i++)
                        row[resultSet.fieldName(i)] = resultSet.field(i);
                    Ti.API.debug(row);
                    resultArray.push(row);
                    resultSet.next();
                }
                resultSet.close();
            }
            callback && callback();
            return resultArray;
        },
        restoreState: function() {
            this.executeQuery("SELECT name FROM sqlite_master WHERE type='table'", [], mapTables);
            return this;
        },
        createTable: function(name, h) {
            this[name] = Object.create(TigerTable());
            this[name].db = db;
            this[name].name = name;
            this[name].executeQuery = this.executeQuery;
            this[name].commit(h);
        },
        destroyTable: function(name) {
            this.executeQuery("DROP TABLE IF EXISTS #{0}".printf(name), [], null);
            delete this[name];
        }
    };
}

var TigerTable = function() {
    this.db = "";
    this.name = "";

    this.commit = function(args) {
        var self = this;
        for (var a = Spine.makeArray(args), i = a.length - 1; i > -1; i--)
            if (a[i] === 'id') {
                a[i] = 'id TEXT NOT NULL PRIMARY KEY';
                break;
            }
        return this.executeQuery("CREATE TABLE IF NOT EXISTS #{0}(#{1})".printf(self.name, a), [], null);
    }

    this.insert = function() {
        var self = this,
			args = Spine.makeArray(arguments),
			qstr = [],
			sendStr = "";
        if (typeof args[0] == "string" || typeof args[0] == "number" ) {
            for (var i = args.length; i > 0; i--) qstr.push("?");
            sendStr = "INSERT OR REPLACE INTO #{0} VALUES (#{1})".printf(self.name, qstr);
        } else {
            var obj = this.deconstruct(args[0]),
				cols = obj[0];
            args = obj[1];
            for (var i = args.length; i > 0; i--) qstr.push("?");
            sendStr = "INSERT OR REPLACE INTO #{0} (#{1}) VALUES (#{2})".printf(self.name, cols, qstr);
        }
        return this.executeQuery(sendStr, args);
    };
    
    this.remove = function() {
        var self = this,
			args = Spine.makeArray(arguments),
			qstr = [],
			sendStr = "";
        if (typeof args[0] == "string" || typeof args[0] == "number" ) {
            for (var i = args.length; i > 0; i--) qstr.push("?");
            sendStr = "DELETE FROM #{0} WHERE ID = (#{1})".printf(self.name, qstr);
        } else {
            var obj = this.deconstruct(args[0]),
				cols = obj[0];
            args = obj[1];
            for (var i = args.length; i > 0; i--) qstr.push("?");
            sendStr = "DELETE FROM #{0} WHERE (#{1}) = (#{2})".printf(self.name, cols, qstr);
        }
        return this.executeQuery(sendStr, args);
    };

    this.find = function() {
		var self = this;
		if (arguments.length == 0)
			return this.executeQuery("select * from #{0}".printf(self.name), []);
		else {
	        var args = Spine.makeArray(arguments);
	        if (Spine.isArray(args[0])) {
	            var sendStr = "select * from #{0} where id in (#{1})".printf(self.name, args[0].join());
				return this.executeQuery(sendStr, []);
	        } else {
				args = args[0];
				var sendStr = [];
	           	for (obj in args) {
					if (args[obj].match(/^[\d\>\<]/))
						sendStr.push("#{0} #{1}".printf(obj,args[obj]));
					else
						sendStr.push("#{0} like '%#{1}%'".printf(obj,args[obj]));
	            }
				var lastStr = "select * from #{0} where ".printf(self.name) + sendStr.join(" and ");
				return this.executeQuery(lastStr, []);
			}
	    }
	};

    this.deconstruct = function(obj) {
        var keys = [],
            vals = [];
        for (var i in obj) {
            keys.push(i);
            vals.push(obj[i]);
        }
        return [keys, vals];
    };

    return this;
}

var dbName = Ti.App.name.replace(/[^a-zA-Z0-9]/g,'');

Spine.Model.TigerDB = {
    db: TigerDB(dbName),
    install: function() {
        this.attributes.push('id');
        this.db.createTable(this.name, this.attributes);
        this.installed = true;
        return this;
    },
    uninstall: function() {
        this.db.destroyTable(this.name);
        this.installed = false;
        return this;
    },
    extended: function() {
        this.sync(this.saveTigerDB);
        this.fetch(this.loadTigerDB);
    },
    saveTigerDB: function(record, method) {
        switch(method) {
            case "create":
            case "update":
                this.db[this.name].insert(record.attributes());
                break;
            case "destroy":
                this.db[this.name].remove(record.id);
                break;
            default:
                ;
        }
        return this;
    },
    loadTigerDB: function() {
        if (!this.installed) this.install();
        var result = this.db[this.name].find();
        if ( !result ) return result;
        return this.refresh(result);
    }
};