defmodule Wallet do
    use GenServer

    def start_link(bitcoins,public_key,private_key,walletnumber,minerPIDs) do
        {:ok,pid} = GenServer.start_link(__MODULE__,[bitcoins, public_key,private_key,minerPIDs],name: {:via, Registry, {:wallets,walletnumber}})
        pid
        # IO.inspect pid
    end

    def init([bitcoins,public_key,private_key,minerPIDs]) do
        state = %{"Bitcoins"=>bitcoins,"PublicKey"=>public_key,"PrivateKey"=>private_key,"minerPIDs"=>minerPIDs}
        {:ok,state}
    end

    def handle_cast({:updateWallet,bitcoins},state) do
        state = Map.put(state,"Bitcoins",bitcoins)
        {:noreply,state}
    end

    def getWallet(pid) do
        GenServer.call(pid,{:getWallet})
    end

    def updateWallet(pid,bitcoins) do
        GenServer.cast(pid,{:updateWallet,bitcoins})
    end

    def walletVerification(walletPID,blockChainPID,senderPID,i,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID) do
        GenServer.call(walletPID,{:verify,blockChainPID,senderPID,i,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID})
    end

    def handle_call({:verify,blockChainPID,senderPID,i,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID},_from,state) do
        receiverWallet = 0
        blockChain = BlockChain.getBlockChain(blockChainPID)
        block = Enum.at(blockChain,length(blockChain)-1)
        sign = Map.get(block, :signedMessage)
        sender_PubKey = Map.get(block, :senderPublicKey)
        {:ok,valid} = RsaEx.verify("message",sign,sender_PubKey)
        transactionData = Map.get(block, :transactionData)
        receiver_PubKey = Map.get(transactionData, "receiverPublicKey")
        wallet_PubKey = Map.get(state, "PublicKey")

        if (wallet_PubKey == receiver_PubKey) do
            :ets.insert(:user_lookup, {"receiverWallet", i}) 
        end
        [{_, verifications}] = :ets.lookup(:user_lookup, "verifications")
        verifications = verifications ++ [valid]
         :ets.insert(:user_lookup, {"verifications", verifications})

         if length(verifications) == Registry.count(:wallets) do
            Main.verified(verifications,blockChainPID,senderPID,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID)
         end

        {:reply,state,state} 
    end

    def handle_call({:getWallet},_from,state) do
        {:reply,state,state}        
    end

    def findPID(walletnumber) do    
        case Registry.lookup(:wallets, walletnumber) do
        [{pid, _}] -> pid
        [] -> nil
        end
    end

    def transaction(senderPID, receiverPID) do
        GenServer.call(senderPID,{:initiateTransaction,receiverPID})
    end

    def handle_call({:initiateTransaction,receiverPID},_from,state) do
        # sender_pid = Wallet.findPID(1)
        # IO.puts "*******************Sender details*******************"
        sender_wallet = state
        sender_PK = Map.get(sender_wallet,"PrivateKey")
        minerPIDs = Map.get(sender_wallet,"minerPIDs")
        sender_PubKey = Map.get(sender_wallet,"PublicKey")
        # IO.puts "Encrpted sender public key: #{inspect(:crypto.hash(:sha256,sender_PubKey)|> Base.encode16)}"
        sender_bitcoins = Map.get(sender_wallet,"Bitcoins")
        # IO.puts "Wallet balance before transaction: #{Float.round(sender_bitcoins,2)}"
        btc = bitcoins(sender_bitcoins)
        :ets.insert(:user_lookup, {"btc", btc}) 
        # IO.puts "Bitcoins to be transfered: #{btc}"
        sender_details = %{"pubkey"=>:crypto.hash(:sha256,sender_PubKey)|> Base.encode16,"bitcoins_beforeTransaction"=>Float.round(sender_bitcoins,2),"btc_toBeTransfered"=>btc}
        # IO.puts "*******************Receiver details*******************"
        # receiver_pid = Wallet.findPID(2)
        receiver_wallet = Wallet.getWallet(receiverPID)
        receiver_PK = Map.get(receiver_wallet,"PublicKey")
        # IO.puts "Encrpted receiver public key: #{inspect(:crypto.hash(:sha256,receiver_PK)|> Base.encode16)}"
        # IO.puts "Wallet balance before transaction: #{Map.get(receiver_wallet,"Bitcoins")}"
        receiver_details = %{"pubkey"=>:crypto.hash(:sha256,receiver_PK)|> Base.encode16,"bitcoins_beforeTransaction"=>Map.get(receiver_wallet,"Bitcoins")}
        # send resultsPID,{:details,[sender_details,receiver_details]}
        transactionData = %{"bitcoins"=>btc,"receiverPublicKey"=>receiver_PK}
        {:ok,signature} = RsaEx.sign("message",sender_PK,:sha256)
        for i <- 1..length(minerPIDs) do
            send Enum.at(minerPIDs,i-1),{:ok,[transactionData,signature,sender_PubKey,self(),sender_details,receiver_details]}
        end
        {:reply,state,state}  
    end

    def bitcoins(a) do
        0 + :rand.uniform() * (a-0)|>Float.round(2)
    end
end