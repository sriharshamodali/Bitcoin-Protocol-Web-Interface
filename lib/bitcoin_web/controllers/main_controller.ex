defmodule BitcoinWeb.MainController do
    use BitcoinWeb, :controller
    
      def finalresult(conn, _params) do

        # 100 Participants in bitcoin peer-peer network
        # 3 Transactions
        Main.run(100,3,self) 

        receive do
          {:details,[results,wallets]}-> 
            results = Map.put(results,"wallets",wallets)   
            temp=Poison.encode!(results)
            json conn,temp
         end
    
      end
  end