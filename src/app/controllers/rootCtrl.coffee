'use strict'
angular.module 'controllers', ['Service']
.controller 'rootCtrl', ['$scope', 'Repo', ($scope, Repo) ->
  $scope.repos = Repo.query()
  $scope.user =
    avatar: "https://avatars2.githubusercontent.com/u/2058684?s=460"
    fullname: "Chunpeng Wen"
    username: "wcp1231"
    followers: 11
    starred: 455
    following: 40

  null
]
