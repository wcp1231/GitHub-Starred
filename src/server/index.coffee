"use strict"
_ = require 'underscore'
express = require 'express'
app = express()

GitHubApi = require 'github'

github = new GitHubApi
  version: '3.0.0',
  debug: true

app.use(express.static("#{__dirname}/public"));
app.use(express.static("#{__dirname}/../bower_components"));

app.get '/user', (req, response) ->
  github.user.getFrom {user: 'wcp1231'}, (err, res) ->
    response.send _.pick(res, 'id', 'avatar_url', 'html_url', 'name', 'login')


app.get '/starred', (req, response) ->
  github.repos.getStarredFromUser {user: 'wcp1231'}, (err, res) ->
    response.send _.map(res, (item) ->
      _.pick(item, 'id', 'full_name', 'description', 'html_url')
    )

app.listen 3000
