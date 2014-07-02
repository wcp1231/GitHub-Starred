'use strict'
r = require 'rethinkdb'
logdebug = require('debug')('rdb:debug')

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

module.exports.connectTest = () ->
  onConnect (err, connection) ->
    if err
      throw err
    console.log('connect!')
    connection.close()

onConnect = (callback) ->
  r.connect {host: dbConfig.host, port: dbConfig.port}, (err, connection) ->
    if err
      throw err
    connection['_id'] = Math.floor Math.random() * 10001
    callback(err, connection)
