'use strict'
angular.module 'controllers', ['Service']
.controller 'rootCtrl', ['$scope', 'Repo', 'User', ($scope, Repo, User) ->
  User.auth().$promise.then (result) ->
    if result.code == 1
      $scope.pageUrl = '/views/login.html'
    else
      $scope.pageUrl = '/views/home.html'
      User.get().$promise.then (result) ->
        $scope.user = result
      Repo.query().$promise.then (repos) ->
        $scope.repos = repos

  null
]
