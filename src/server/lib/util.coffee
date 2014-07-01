'use strict'
GitHubApi = require 'github'
https = require 'https'
querystring = require 'querystring'

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
    client_id: '71ace902e2fd52547831'
    client_secret: '62dab9eddf0e0c83cf5e05b779fc13673d516ccd'
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
