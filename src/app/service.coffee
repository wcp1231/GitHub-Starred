'use strict'
angular.module('Service', ['ngResource'])
  .factory 'Repo', ($resource) ->
    $resource '/repo/:Id', {Id: '@Id' },
      'get':
        method: 'GET'
      'query':
        method: 'GET'
        isArray: true
      'save':
        method: 'PUT'
      'remove':
        method: 'DELETE'
      'updateRepos':
        method: 'GET'
        isArray: true
        url: 'updateRepos'
      'getReadme':
        method: 'GET'
        url: 'getReadme'

  .factory 'User', ($resource) ->
    $resource '/user/:Id', { Id: '@Id'},
      'get':
        method: 'GET'
      'auth':
        method: 'GET',
        url: 'auth'
