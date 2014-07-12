'use strict'
_ = require 'underscore'
r = require 'rethinkdb'
logdebug = require('debug')('rdb:debug')
logerror = require('debug')('rdb:error')

dbConfig =
  host: process.env.RDB_HOST || 'localhost'
  port: parseInt(process.env.RDB_PORT) || 28015
  db: process.env.RDB_DB || 'githubStarred'
  tables:
    'users': 'id'
    'repos': 'id'
    'relationship': 'id'

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
      r.db(dbConfig.db).table('relationship').indexCreate('repoId').run connection, (err, result) ->
        if err
          logerror '[ERROR] create index error. %s:%s\n%s', err.name, err.msg, err.message

module.exports.findUserByName = (name, callback) ->
  onConnect (err, connection) ->
    r.table('users').filter({ 'login': name }).run connection, (err, cursor) ->
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
    userTable = r.table('users')
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

module.exports.saveRepos = (repos, callback) ->
  onConnect (err, connection) ->
    repoTable = r.table('repos')
    repos.forEach (repo, index) ->
      repoTable.get(repo.id).replace(repo).run connection, (err, res) ->
        if err
          logerror '[ERROR][%s][saveRepo] %s:%s\n%s', connection['_id'], err.name, err.msg, err.message
          callbace err
    callback null

module.exports.getUserStarred = (userId, callback) ->
  onConnect (err, conn) ->
    r.table('relationship')
      .filter({ userId: userId })
      .eqJoin('repoId', r.table('repos'))
      .run conn, (err, cursor) ->
        if err
          logerror '[ERROR][%s][getUserStarred] %s:%s\n%s', conn['_id'], err.name, err.msg, err.message
          callback err
        else
          cursor.toArray (err, result) ->
            callback null, result

module.exports.deleteRelationship = (userId, reposId, callback) ->
  if reposId.length <= 0
    callback null, {deleted: 0}
    return
  onConnect (err, conn) ->
    relTable = r.table('relationship')
    reposId.push { index: 'repoId' }
    relTable.getAll.apply(relTable, reposId).delete().run conn, (err, result) ->
      if err
        logerror '[ERROR][%s][deleteRelationship] %s:%s\n%s', conn['_id'], err.name, err.msg, err.message
        callback err
      else
        callback null, result

module.exports.insertRelationship = (userId, reposId, callback) ->
  onConnect (err, conn) ->
    data = _.map reposId, (id) ->
      userId: userId
      repoId: id
    r.table('relationship').insert(data).run conn, (err, result) ->
      if err
        logerror '[ERROR][%s][insertRelationship] %s:%s\n%s', conn['_id'], err.name, err.msg, err.massage
        callback err
      else
        callback null, result

module.exports.connectTest = () ->
  onConnect (err, connection) ->
    console.log('connect!')
    connection.close()

onConnect = (callback) ->
  r.connect {host: dbConfig.host, port: dbConfig.port}, (err, connection) ->
    if err
      throw err
    connection['_id'] = Math.floor Math.random() * 10001
    connection.use dbConfig.db
    callback(err, connection)
