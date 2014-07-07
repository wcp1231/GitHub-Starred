'use strict'
_ = require 'underscore'
express = require 'express'
path = require "path"
session = require 'express-session'
util = require './lib/util'
app = express()

app.use(express.static(path.join(__dirname, 'public')))
app.use(express.static('#{__dirname}/../bower_components'))

app.use(session({ secret: 'keyboard cat' }))

restrict = (req, res, next) ->
  if req.session.user
    next()
  else
    res.redirect '/loginRequire'

login = (req, token, cb) ->
  req.session.regenerate (err) ->
    req.session.user = token
    cb()

app.get '/loginRequire', (req, res) ->
  res.send('{"msg": "Login Require!"}')

app.get '/callback', (req, res) ->
  util.requireToken req.query.code, (result) ->
    login req, result.access_token, () ->
      res.redirect('/')

app.get '/user', restrict, (req, response) ->
  token = req.session.user
  github = util.generateGitHubClient token
  github.user.getFrom {user: 'wcp1231'}, (err, res) ->
    response.send _.pick(res, 'id', 'avatar_url', 'html_url', 'name', 'login')


app.get '/repo', restrict, (req, response) ->
  token = req.session.user
  github = util.generateGitHubClient token
  github.repos.getStarredFromUser {user: 'wcp1231'}, (err, res) ->
    response.send _.map(res, (item) ->
      _.pick(item, 'id', 'full_name', 'description', 'html_url')
    )

app.listen 3000
