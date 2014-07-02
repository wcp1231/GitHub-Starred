'use strict'
angular.module 'controllers', ['Service']
.controller 'rootCtrl', ['$scope', 'Repo', 'User', ($scope, Repo, User) ->
  User.get().$promise.then (result) ->
    if result.msg and result.msg == 'Login Require!'
      $scope.pageUrl = '/views/login.html'
    else
      $scope.user = result
      $scope.pageUrl = '/views/home.html'
      Repo.query().$promise.then (repos) ->
        $scope.repos = repos

  null
]
