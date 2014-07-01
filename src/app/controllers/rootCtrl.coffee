'use strict'
angular.module 'controllers', ['Service']
.controller 'rootCtrl', ['$scope', 'Repo', ($scope, Repo) ->
  $scope.pageUrl = '/views/login.html'
  $scope.repos = Repo.query()
  $scope.user =
    avatar: "https://avatars2.githubusercontent.com/u/2058684?s=460"
    fullname: "Chunpeng Wen"
    username: "wcp1231"
    followers: 11
    starred: 455
    following: 40

  $scope.repos.$promise.then (repos) ->
    $scope.repos = repos
    $scope.pageUrl = '/views/home.html'

  null
]
