###
Version b2 Rev. 1 July 2012
Version a02 Rev. 15th Oct 2008


TigerDB by Charles Phillips <charles@doublerebel.com>
Designed for Tiger for Spine on Titanium 0.0.2+
Persistent storage through Titanium's SQLite DB

Based on javascript-client-side-sqlite3-wrapper
http://code.google.com/p/javascript-client-side-sqlite3-wrapper/


Tested working on Safari 5525.20.1 (should work in Chrome as well?)
and will not work in Firefox cause Gears interface has not been
implemented. Only INSERT and FIND are working.

USE AS FOLLOW:
To create a new local database and then a table on the client's machine:

   storage = LocalStorage('DatabaseName')
   storage.createTable('Phonebook','Name','Number')

Note that TABLES MUST START with a CAPITAL letter. When a table is created,
it is automatically mapped as a method/property of the storage that created
it. Hence we can write:

   storage.Phonebook

To get to that table and perform CRUD operations on it.

------ INSERT ------

INSERTS can take two forms.

   storage.Phonebook.insert('Girl Next Door','555-000-001')

Or, the second form allows us to stuff a hash (interchangeably an object in
Javascript) into the table. We declare an object/hash.

   person = {}
   person['Name'] = "Girl Next Door"
   person['Number'] = "555-000-001"
   storage.Phonebook.insert(person)

Similarly, we could have also declared the object as:

   person = {  Name: "Girl Next Door",
         Number: "555-000-001"   }

Note: NO ERROR CHECKING has currently been implemented, if you spell the
field names wrong, or give it too many/few parameters, the operation will
fail silently! (In JS, but Titanium will throw an SQLite error)

Sidenote on allowing this "object form" is that it could be possible
to persist arbitrary Javascript objects with the database#without knowing
beforehand* their properties since SQLite can add more columns when needed
on the fly!

------ FIND ------

#find takes two forms (and a 1/2!). To retrieve all rows in a table:

   storage.Phonebook.find()

All SQLite tables have an implicit rowid column which is unique. We can
therefore -- like in Rails -- pass #find an array of rowid's:

   storage.Phonebook.find([1,2,3,4,5])

The more customary approach is to query using one/multiple conditions
(e.g. the WHERE SQL expression). To do this we pass #find a hash.

   storage.Phonebook.find( { Name:'Girl Next Door',Number:'555' } )

Here the "contains" clause is implied, as in the field contains the
string (e.g. SQLite's#like* keyword). If the column contains numeric
data, then we would query it like this.

   storage.Players.find( {Wins:'>10'} )

The conditionals are passed in as strings and plugged into the SQL statement.
There are six million things wrong with doing this. Further TO DO's for
#find include searching DATETIME and possibly pagination (as in return how
many rows per page and how many pages).

------- RESTORING ON PAGE RELOAD -------

When the page is reloaded, restoring the mapping of the storage to
its tables is achieved by calling:

   storage.restoreState()

Hence, this statement should almost always be called right after
the storage is instantiated.
###


Tiger = @Tiger or require './tiger'
Model = Tiger.Model


class TigerDB extends Tiger.Class
  @include Tiger.Log

  constructor: (dbName) ->
    try
      @debug "Opening Database #{dbName}"
      if Ti.Database then @db = Ti.Database.open(dbName)
      else @debug "No Ti.Database."
    catch err
      @debug "Couldn't open the database."

  mapTable = (tableName) ->
    @[tableName] = new TigerTable @db, tableName, @executeQuery
    @debug @[tableName].name

  mapTables = (row) ->
    if row.name.match /^[A-Z]/ then mapTable row.name

  executeQuery: (string, args, callback) ->
    args = (/^[0-9]+\.?[0-9]*$/.exec(arg) and "\"#{String arg}\"" or arg for arg in args)
    @debug "SQL: #{string} | #{args.join()}"

    resultSet = @db.execute string, args
    resultArray = []

    if resultSet
      fields = if Ti.Platform.osname is 'android' then resultSet.fieldCount else resultSet.fieldCount()
      while resultSet.isValidRow()
        row = {}
        for i in [0..fields-1]
          rawValue = resultSet.field(i)
          try
            value = JSON.parse rawValue
          catch error
            value = rawValue
          row[resultSet.fieldName(i)] = value
        @debug "Result: #{JSON.stringify row}"
        resultArray.push(row)
        resultSet.next()
      resultSet.close()

    if callback then callback()
    resultArray

  restoreState: ->
    @executeQuery "SELECT name FROM sqlite_master WHERE type='table'", [], mapTables
    @

  createTable: (name, columns) ->
    @[name] = new TigerTable @db, name, @executeQuery
    @[name].commit(columns)

  destroyTable: (name) ->
    @executeQuery "DROP TABLE IF EXISTS #{name}", [], null
    delete @[name]


class TigerTable extends Tiger.Class
  @include Tiger.Log

  constructor: (@db = "", @name = "", @executeQuery) ->

  commit: (attributes) ->
    columns = Tiger.makeArray attributes
    for i of columns when columns[i] is "id"
      columns[i] = "id TEXT NOT NULL PRIMARY KEY"
      break
    sendStr = "CREATE TABLE IF NOT EXISTS #{@name}(#{columns})"
    @executeQuery sendStr, [], null

  insert: (args...) ->
    qStr = []
    sendStr = ""

    if typeof args[0] is "string" or typeof args[0] is "number"
      qStr.push("?") for i in args
      sendStr = "INSERT OR REPLACE INTO #{@name} VALUES (#{qStr})"
    else
      [cols, args] = @deconstruct args[0]
      qStr.push("?") for i in args
      sendStr = "INSERT OR REPLACE INTO #{@name} (#{cols}) VALUES (#{qStr})"
    @executeQuery sendStr, args

  remove: (args...) ->
    qStr = []
    sendStr = ""

    if typeof args[0] is "string" or typeof args[0] is "number"
      qStr.push("?") for i in args
      sendStr = "DELETE FROM #{@name} WHERE ID = (#{qStr})"
    else
      [cols, args] = @deconstruct args[0]
      qStr.push("?") for i in args
      sendStr = "DELETE FROM #{@name} WHERE (#{cols}) = (#{qStr})"
    @executeQuery sendStr, args

  all: ->
    @executeQuery "select * from #{@name}", []

  find: (args...) ->
    return @all() unless args.length
    if Tiger.isArray args[0]
      sendStr = "select * from #{@name} where id in (#{args[0].join()})"
      return @executeQuery sendStr, []
    else
      args = args[0]
      sendStr = []

      for key, val of args
        if val.match(/^[\d\>\<]/)
          sendStr.push "#{key} #{val}"
        else
          sendStr.push "#{key} like '%#{val}%'"

      lastStr = "select * from #{@name} where " + sendStr.join(" and ")
      @executeQuery lastStr, []

  deconstruct: (obj) ->
    keys = []
    vals = []
    for key, val of obj
      keys.push key
      vals.push if typeof val is 'object' then JSON.stringify val else val
    [keys, vals]


dbName = Ti.App.name.replace(/[^a-zA-Z0-9]/g,"")

Model.TigerDB =
  db: new TigerDB dbName

  install: ->
    @attributes.push("id") unless "id" in @attributes
    @db.createTable @name, @attributes
    @installed = true
    @

  uninstall: ->
    @db.destroyTable @name
    @installed = false
    @

  extended: ->
    Tiger.Log.debug "extending Tiger.DB"
    @change @updateTigerDB
    @fetch @loadTigerDB

  updateTigerDB: (record, method) ->
    Tiger.Log.debug "Update DB: #{method}", record.attributes()
    switch method
      when "create", "update"
        @db[@name].insert record.attributes()
      when "destroy"
        @db[@name].remove record.id
      else
    @

  loadTigerDB: (filter) ->
    Tiger.Log.debug "Loading Database Table #{@name}"
    @install() unless @installed
    result = if filter then @db[@name].find filter else @db[@name].all()
    if not result then result
    else @refresh result


Tiger.DB        = TigerDB
module?.exports = TigerDB
