'use strict'
angular.module 'controllers', ['Service']
.controller 'rootCtrl', ['$scope', '$filter', 'Repo', 'User', ($scope, $filter, Repo, User) ->
  User.auth().$promise.then (result) ->
    if result.code == 1
      $scope.pageUrl = '/views/login.html'
    else
      $scope.pageUrl = '/views/home.html'
      User.get().$promise.then (result) ->
        $scope.user = result
      Repo.query().$promise.then (repos) ->
        $scope.repos = repos
      Repo.updateRepos().$promise.then (repos) ->
        if repos.length > 0
          $scope.repos = repos

  $scope.refresh = () ->
    Repo.updateRepos().$promise.then (repos) ->
      if repos.length > 0
        $scope.repos = repos

  $scope.select = ($event, repo) ->
    prev = $filter('filter')($scope.repos, {selected: true})[0]
    if prev
      prev.selected = false
    repo.selected = true

  null
]
