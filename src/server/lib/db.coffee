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
