'use strict'
GitHubApi = require 'github'
https = require 'https'
querystring = require 'querystring'
config = require '../config'

exports.generateGitHubClient = (token) ->
  github = new GitHubApi
    version: '3.0.0',
    debug: true
  github.authenticate
    type: 'oauth'
    token: token
  github

exports.requireToken = (code, cb) ->
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
