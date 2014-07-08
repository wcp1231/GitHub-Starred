'use strict'
r = require 'rethinkdb'
logdebug = require('debug')('rdb:debug')
logerror = require('debug')('rdb:error')

dbConfig =
  host: process.env.RDB_HOST || 'localhost'
  port: parseInt(process.env.RDB_PORT) || 28015
  db: process.env.RDB_DB || 'gitStart'
  tables:
    'users': 'id'
    'repos': 'id'

module.exports.setup = () ->
  r.connect {host: dbConfig.host, port: dbConfig.port}, (err, connection) ->
    if err
      throw err
    r.dbCreate(dbConfig.db).run connection, (err, result) ->
      if err
        logdebug '[DEBUG] RethinkDB database "%s" already exists (%s:%s)\n%s', dbConfig.db, err.name, err.msg, err.message
      else
        logdebug '[INFO ] RethinkDB database "%s" created', dbConfig.db
      for tb, _id of dbConfig.tables
        `(function (tableName) {
            r.db(dbConfig.db).tableCreate(tableName, {primaryKey: _id}).run(connection, function(err, result) {
              if(err) {
                logdebug('[DEBUG] RethinkDB table "%s" already exists (%s:%s)\n%s', tableName, err.name, err.msg, err.message);
              } else {
                logdebug('[INFO ] RethinkDB table "%s" created', tableName);
              }
            });
          })(tb)
        `

module.exports.findUserByName = (name, callback) ->
  onConnect (err, connection) ->
    r.db(dbConfig.db).table('users').filter({ 'login': name }).run connection, (err, cursor) ->
      if err
        logerror '[ERROR][%s][findUserByName][collect] %s:%s\n%s', connection['_id'], err.name, err.msg, err.message
        callback err
      else
        cursor.next (err, row) ->
          if err
            logerror '[ERROR][%s][findUserByEmail][collect] %s:%s\n%s', connection['_id'], err.name, err.msg, err.message
            callback err
          else
            callback null, row
          connection.close()

module.exports.saveUser = (user, callback) ->
  onConnect (err, connection) ->
    userTable = r.db(dbConfig.db).table('users')
    userTable.insert(user).run connection, (err, result) ->
      if err
        logerror '[ERROR][%s][saveUser] %s:%s\n%s', connection['_id'], err.name, err.msg, err.message
        callback err
        connection.close()
      else if result.inserted == 1
        callback null, true
        connection.close()
      else
        userTable.get(user.id).update(user).run connection, (err, result) ->
          if err
            logerror '[ERROR][%s][updateUser] %s:%s\n%s', connection['_id'], err.name, err.msg, err.message
            callback err
          else if result.errors > 0
            logdebug '[DEBUG][%s][updateUser] number of errors: %s', connection['_id'], result.errors
            callback null, false
          else
            callback null, true
          connection.close()

module.exports.connectTest = () ->
  onConnect (err, connection) ->
    console.log('connect!')
    connection.close()

onConnect = (callback) ->
  r.connect {host: dbConfig.host, port: dbConfig.port}, (err, connection) ->
    if err
      throw err
    connection['_id'] = Math.floor Math.random() * 10001
    callback(err, connection)
