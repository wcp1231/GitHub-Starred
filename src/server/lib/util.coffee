'use strict'
_ = require 'underscore'
GitHubApi = require 'github'
https = require 'https'
querystring = require 'querystring'
db = require './db'
config = require '../config'
logdebug = require('debug')('util:debug')
logerror = require('debug')('htil:error')

module.exports.generateGitHubClient = (token) ->
  github = new GitHubApi
    version: '3.0.0',
    debug: false
  github.authenticate
    type: 'oauth'
    token: token
  github

module.exports.requireToken = (code, cb) ->
  postData = querystring.stringify
    client_id: config.client_id
    client_secret: config.client_secret
    code: code

  options =
    host: 'github.com'
    port: 443
    path: '/login/oauth/access_token'
    method: 'POST'
    headers:
      Accept: 'application/json'
      'Content-Type': 'application/x-www-form-urlencoded'
      'Content-Length': postData.length

  req = https.request options, (res) ->
    result = ''
    res.on 'data', (data) ->
      result = JSON.parse data.toString()
    res.on 'end', () ->
      cb(result)
  req.write postData
  req.end()

module.exports.getAllStarredRepos = (github, callback) ->
  logdebug '[INFO] getAllStarred'
  result = []
  nextPage = (link) ->
    if github.hasNextPage link
      logdebug '[DEBUG][getStarred] %s', link.meta.link
      github.getNextPage link, (err, res) ->
        if err
          logerror '[ERROR][getStarred] %s:%s\n%s', err.name, err.msg, err.message
          callback err, null
        result = result.concat _.map(res, (item) ->
          _.pick item, 'id', 'full_name', 'description', 'html_url'
        )
        nextPage res
    else
      callback null, result
  github.repos.getStarred {}, (err, res) ->
    if err
      logerror '[ERROR][getStarred] %s:%s\n%s', err.name, err.msg, err.message
      callback err, null
    result = result.concat _.map(res, (item) ->
      _.pick item, 'id', 'full_name', 'description', 'html_url'
    )
    nextPage res

module.exports.updateRepos = (user, repos, callback) ->
  allReposId = _.pluck repos, 'id'
  userStarredId = _.pluck user.starred, 'id'
  deletedId = _.difference userStarredId, allReposId
  newId = _.difference allReposId, userStarredId
  user.starred = _.reject user.starred, (r) ->
    _.contains deletedId, r.id
  user.starred = _.map(newId, (id) -> { id: id }).concat user.starred
  db.saveUser user, () -> {}
  db.saveRepos repos, callback
