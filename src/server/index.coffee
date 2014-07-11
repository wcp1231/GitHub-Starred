'use strict'
_ = require 'underscore'
express = require 'express'
path = require "path"
session = require 'express-session'
util = require './lib/util'
db = require './lib/db'
logdebug = require('debug')('http:debug')
logerror = require('debug')('http:error')
app = express()

app.use(express.static(path.join(__dirname, 'public')))
app.use(express.static('#{__dirname}/../bower_components'))

app.use(session({ secret: 'keyboard cat' }))

restrict = (req, res, next) ->
  if req.session.user
    next()
  else
    res.redirect '/loginRequire'

login = (req, res, token) ->
  github = util.generateGitHubClient token
  github.user.get {}, (err, result) ->
    req.session.regenerate (err) ->
      user = _.pick result, 'id', 'avatar_url', 'html_url', 'name', 'login'
      db.saveUser user, (err, success) ->
        logdebug '[DEBUG][saveUser] %s', success
        if err
          logerror '[ERROR][saveUser] %s:%s:\n%s', err.name, err.msg, err.message
        else if success
          req.session.userId = user.id
          req.session.user = user.login
          req.session.token = token
          req.session.updated = false
        res.redirect '/'

app.get '/loginRequire', (req, res) ->
  res.send('{"msg": "Login Require!"}')

app.get '/callback', (req, res) ->
  util.requireToken req.query.code, (result) ->
    login req, res, result.access_token

app.get '/auth', (req, res) ->
  if req.session.user
    res.send '{"msg": "login", "code": 0}'
  else
    res.send '{"msg": "not login", "code": 1}'

app.get '/user', restrict, (req, res) ->
  name = req.session.user
  db.findUserByName name, (err, result) ->
    res.send result

app.get '/repo', restrict, (req, res) ->
  userId = req.session.userId
  db.getUserStarred userId, (err, repos) ->
    res.send repos

app.get '/updateRepos', restrict, (req, res) ->
  if req.session.updated
    res.send []
  token = req.session.token
  username = req.session.user
  github = util.generateGitHubClient token
  util.getAllStarredRepos github, (err, repos) ->
    if err
      res.send '[]'
    else
      db.findUserByName username, (err, user) ->
        util.updateRepos user, repos, () ->
          logdebug '[INFO] update repos finish'
          req.session.updated = true
          res.send repos

app.listen 3000
