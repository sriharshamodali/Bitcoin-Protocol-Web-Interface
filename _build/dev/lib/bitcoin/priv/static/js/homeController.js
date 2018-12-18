var app = angular.module('bitcoin', []);


app.controller("HomeController", [
    "$scope","$http", function ($scope,$http) {

      $scope.submitbutton = true;
      $scope.showgraph = false;
      $scope.showbutton = false;
      $("#loaderDiv").hide();

      $scope.submit = function()
      {
        $('html,body').animate({
          scrollTop: $("#loaderDiv").offset().top},
          'slow');
        $scope.showgraph = false;
        $("#loaderDiv").show();
        $scope.showbutton = true;
        $scope.result = [];
        $scope.senderBTC_before = [];
        $scope.senderBTC_after = [];
        $scope.receiverBTC_before = [];
        $scope.receiverBTC_after = [];
        $scope.BTCtransfered = [];
        $scope.Transactionlabels = [];
        $scope.walletlabels = [];
        $scope.submitbutton = false;
        $scope.wallets = [];
        serverURL = "http://localhost:4000/result";
        $http.get(serverURL,{ timeout: 300000 }).then(function (response) {
          
          console.log(response)
          $scope.result = JSON.parse(JSON.parse(response.data))
          $scope.wallets = $scope.result.wallets;
          delete $scope.result["wallets"];
          
          
          angular.forEach($scope.result, function(result,key){
            $scope.senderBTC_before.push(Number((result.SenderDetails.bitcoins_beforeTransaction).toFixed(2)));
            $scope.senderBTC_after.push(Number((result.UpdatedSenderBTC).toFixed(2)));
            $scope.receiverBTC_before.push(Number((result.ReceiverDetails.bitcoins_beforeTransaction).toFixed(2)));
            $scope.receiverBTC_after.push(Number((result.UpdatedReceiverBTC).toFixed(2)));
            $scope.BTCtransfered.push(Number((result.SenderDetails.bitcoins_beforeTransaction-result.UpdatedSenderBTC).toFixed(2)));
            $scope.Transactionlabels.push("Transaction " + key);
          });

          angular.forEach($scope.wallets,function(wallet,key){
            var num = parseInt(key) + 1
            $scope.walletlabels.push("Wallet " + num.toString())
          });

            $scope.senderDetails_beforeTransaction();
            $scope.senderDetails_afterTransaction();
            $scope.ReceiverDetails_beforeTransaction();
            $scope.ReceiverDetails_afterTransaction();
            $scope.bitcoinsTransfered();
            $scope.walletsChart();
          
          $scope.showgraph = true;
          $scope.showbutton = false;
          $("#loaderDiv").hide();
          $('html, body').animate({scrollTop:$(document).height()}, 'slow');
          }, function (error) {
          
            console.log(error)
          
          });

      };


      $scope.senderDetails_beforeTransaction = function()
      {
        var ctx = document.getElementById("senderDetails_before").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'doughnut',
         data: {
            labels: $scope.Transactionlabels,
          datasets: [
            {
             backgroundColor: ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             borderColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             pointBackgroundColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             data: $scope.senderBTC_before
            }
           ]
         },
         options: {
          title: {
            display: true,
            text: 'Sender Wallet Before Transaction'
        },
        legend: { display: true },
         }
       });
      };

      $scope.senderDetails_afterTransaction = function()
      {
        var ctx = document.getElementById("senderDetails_after").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'doughnut',
         data: {
            labels: $scope.Transactionlabels,
          datasets: [
            {
              backgroundColor: ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              borderColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              pointBackgroundColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             data: $scope.senderBTC_after
            }
           ]
         },
         options: {
          title: {
            display: true,
            text: 'Sender Wallet After Transaction'
        },
        legend: { display: true },
         }
       });
      };

      $scope.ReceiverDetails_beforeTransaction = function()
      {
        var ctx = document.getElementById("receiverDetails_before").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'pie',
         data: {
            labels: $scope.Transactionlabels,
          datasets: [
            {
              backgroundColor: ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             borderColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             pointBackgroundColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             data: $scope.receiverBTC_before
            }
           ]
         },
         options: {
          title: {
            display: true,
            text: 'Receiver Wallet Before Transaction'
        },
        legend: { display: true },
         }
       });
      };

      $scope.ReceiverDetails_afterTransaction = function()
      {
        var ctx = document.getElementById("receiverDetails_after").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'pie',
         data: {
            labels: $scope.Transactionlabels,
          datasets: [
            {
              backgroundColor: ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              borderColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              pointBackgroundColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             data: $scope.receiverBTC_after
            }
           ]
         },
         options: {
          title: {
            display: true,
            text: 'Receiver Wallet After Transaction'
        },
        legend: { display: true },
         }
       });
      };

      $scope.bitcoinsTransfered = function()
      {
        var ctx = document.getElementById("bitcoinsTransfered").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'polarArea',
         data: {
            labels: $scope.Transactionlabels,
          datasets: [
            {
              backgroundColor: ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              borderColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
              pointBackgroundColor:   ["rgba(33, 181, 197)","rgba(222, 190, 7)","rgba(222, 181, 197)"],
             label: "Bitcoins Transfered",
             data: $scope.BTCtransfered,
            //  backgroundColor: ["rgba(19, 172, 165)","rgba(254, 206, 16)"],
            //  borderColor:  ["rgba(19, 172, 165)","rgba(254, 206, 16)"],
            //  pointBackgroundColor: ["rgba(19, 172, 165)","rgba(254, 206, 16)"]
            }
           ]
         },
         options: {
          title: {
            display: true,
            text: 'Bitcoins Transfered'
        },
        legend: { display: true },
         }
       });
      };

      $scope.walletsChart = function()
      {
        var ctx = document.getElementById("walletschart").getContext('2d');

      var myChart = new Chart(ctx, {
        type: 'bar',
         data: {
            labels: $scope.walletlabels,
          datasets: [
            {
              backgroundColor: "rgba(155, 89, 182,0.8)",
              borderColor: "rgba(142, 68, 173,1.0)",
              pointBackgroundColor: "rgba(142, 68, 173,1.0)",
             data: $scope.wallets
            }
           ]
         },
         options: {
          scales: {
           yAxes: [{
            ticks: {
             beginAtZero:true
            },
            scaleLabel: {
              display: true,
              labelString: 'Number of bitcoins in each wallet'
            }
           }]
          },
          title: {
            display: true,
            text: 'Wallets with corresponding BTC in Bitcoin Peer-Peer Network'
        },
        legend: { display: false },
         }
       });
      }
      
    
    }]);