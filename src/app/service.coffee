angular.module("Service", ["ngResource"]).
  factory "Repo", ($resource) ->
    $resource "/repo/:Id", {Id: "@Id" },
      "get":
        method: "GET"
      "query":
        method: "GET"
        isArray: true
      "save":
        method: "PUT"
      "remove":
        method: "DELETE"
