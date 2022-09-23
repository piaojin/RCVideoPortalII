'use strict';

var app = angular.module('EnvEditor', ['JSONedit']);

function MainViewCtrl($scope, $http, $filter) {
    $http.get('/conf')
       .then(function(res){
          $scope.jsonData = res.data;
        });

    $scope.jsonData = {};

    $scope.$watch('jsonData', function(json) {
        $scope.jsonString = $filter('json')(json);
    }, true);
    $scope.$watch('jsonString', function(json) {
        try {
            $scope.jsonData = JSON.parse(json);
            $scope.wellFormed = true;
            $("#submitButton").prop( "disabled", false );
        } catch(e) {
            $scope.wellFormed = false;
            $("#submitButton").prop( "disabled", true );
        }
    }, true);
}
