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
  console.trace('call getAllStarred')
  result = []
  pickData = (item) ->
    item = _.pick item, 'id', 'name', 'description', 'html_url', 'owner', 'language'
    item.owner = _.pick item.owner, 'login', 'html_url'
    if not item['language']
      item['language'] = 'Unknow'
    item

  nextPage = (link) ->
    if github.hasNextPage link
      logdebug '[DEBUG][getStarred] %s', link.meta.link
      github.getNextPage link, (err, res) ->
        if err
          logerror '[ERROR][getStarred] %s:%s\n%s', err.name, err.msg, err.message
          callback err, null
        result = result.concat _.map(res, pickData)
        nextPage res
    else
      callback null, result

  github.repos.getStarred {}, (err, res) ->
    if err
      logerror '[ERROR][getStarred] %s:%s\n%s', err.name, err.msg, err.message
      callback err, null
    result = result.concat _.map(res, pickData)
    nextPage res

module.exports.updateRepos = (user, repos, callback) ->
  db.getUserStarred user.id, (err, starred) ->
    allReposId = _.pluck repos, 'id'
    starredId = _.pluck starred, 'repoId'
    deletedId = _.difference starredId, allReposId
    newId = _.difference allReposId, starredId
    db.insertRelationship user.id, newId, (err, result) ->
      logdebug '[INFO] insert relation %s', result.inserted
    db.deleteRelationship user.id, deletedId, (err, result) ->
      logdebug '[INFO] delete relation %s', result.deleted
    db.saveRepos repos, () ->
      db.getUserStarred user.id, (err, repos) ->
        callback repos

module.exports.getReadme = (github, repo, callback) ->
  github.repos.getReadme
    user: repo.owner.login
    repo: repo.name
    , (err, response) ->
      source = (new Buffer response.content, 'base64').toString()
      github.markdown.render
        text: source
        , (err, result) ->
          repo.readme = result.data
          db.updateRepo repo, (err, res) ->
            if err
              callback ''
            else
              callback repo.readme
