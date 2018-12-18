defmodule Main do

def main(args) do
    args |> parse_args
end

defp parse_args(args) do
    {_,parameters,_} = OptionParser.parse(args,switches: [ name: :string],aliases: [ h: :name])
    participants = String.to_integer(Enum.at(parameters,0))
    numTransactions = String.to_integer(Enum.at(parameters,1))
    resultsPID = ""
    run(participants,numTransactions,resultsPID)
end

def createKeys() do
  {:ok,{private_key,public_key}} = RsaEx.generate_keypair("512")
  {private_key,public_key}
end

def run(participants,numTransactions,resultsPID) do
    Registry.start_link(keys: :unique, name: :wallets)
    :ets.new(:user_lookup, [:set, :public, :named_table])
    :ets.insert(:user_lookup, {"verifications", []})
    :ets.insert(:user_lookup, {"receiverWallet", 0})
    :ets.insert(:user_lookup, {"btc", 0})
    :ets.insert(:user_lookup, {"results", %{}})

    blockChainPID = BlockChain.start_link()
    blockChain = BlockChain.getBlockChain(blockChainPID)

    transactions_pid = spawn(Main, :createTransactions,[0,numTransactions,participants,blockChainPID,self(),resultsPID])

    blockVerificationPID = spawn(Main, :blockVerification, [blockChainPID,"",transactions_pid,resultsPID])
  
    minerPIDs = Enum.reduce(Enum.to_list(1..10),[],
    fn(x,acc)-> minerPID = spawn(Mining, :miner, [blockChainPID,blockVerificationPID])
    [minerPID | acc] end)

    for i <- 1..participants do
      bitcoins = Float.round(:random.uniform()*10,2)
      {private_key,public_key} = createKeys()
      pid = Wallet.start_link(bitcoins,public_key,private_key,i,minerPIDs)
    end
    send transactions_pid,{:startTransaction}

    receive do
      {:completed} -> {:completed}

    end
  # end

  
end



def pairs(num,participants,map_set) do
  if num == MapSet.size(map_set) do
    map_set
  else
    x = Enum.random(Enum.to_list(1..50-1))
    map_set = MapSet.put(map_set,x)
    pairs(num,participants,map_set)
  end
 end

def blockVerification(blockChainPID,senderPID,transactions_pid,resultsPID) do

  receive do
    {:ok,[sender,sender_details,receiver_details,msgt_hash]} -> #IO.puts "Payment in processing..........."
                      blockChain = BlockChain.getBlockChain(blockChainPID)
                      block = Enum.at(blockChain,length(blockChain)-1) 
                      for i<-1..Registry.count(:wallets) do
                        walletPID = Wallet.findPID(i)
                        Wallet.walletVerification(walletPID,blockChainPID,sender,i,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID)
                      end
                      blockVerification(blockChainPID,senderPID,transactions_pid,resultsPID)     
                      # Main.blockVerification(counter,blockChainPID,sender)           
  end
  
end


  def verified(verifications,blockChainPID,senderPID,transactions_pid,sender_details,receiver_details,msgt_hash,resultsPID) do

    [{_, receiverWallet}] = :ets.lookup(:user_lookup, "receiverWallet")
    [{_, btc}] = :ets.lookup(:user_lookup, "btc")
    if length(verifications) == Registry.count(:wallets) do
      trues = Enum.filter(verifications,fn(x)-> x == true end)

      if (length(trues) == Registry.count(:wallets)) do
        # IO.puts "New block in the block chain has been verified by all the peers in the P2P Network"
        sender_wallet = Wallet.getWallet(senderPID)
        bitcoins = Map.get(sender_wallet,"Bitcoins")
        Wallet.updateWallet(senderPID,bitcoins - btc) 
        updated_sender_wallet =  Wallet.getWallet(senderPID)
        updated_sender_bitcoins = Map.get(updated_sender_wallet,"Bitcoins")
        receiver_walletPID = Wallet.findPID(receiverWallet)
        receiver_wallet = Wallet.getWallet(receiver_walletPID)
        before_btc = Map.get(receiver_wallet,"Bitcoins")
        Wallet.updateWallet(receiver_walletPID,before_btc + btc) 

        receiver_wallet = Wallet.getWallet(receiver_walletPID)
        updated_receiver_bitcoins = Map.get(receiver_wallet,"Bitcoins")

        send transactions_pid,{:transactionCompleted,[updated_sender_bitcoins,updated_receiver_bitcoins,sender_details,receiver_details,msgt_hash,resultsPID]}

        :ets.insert(:user_lookup, {"verifications", []})
        :ets.insert(:user_lookup, {"btc", 0})
       
      else
        IO.puts "Transaction unsuccessful !!!"
        blockChain = BlockChain.getBlockChain(blockChainPID)
        blockChain = List.delete_at(blockChain,length(blockChain)-1)
        BlockChain.changeBlockChain(blockChainPID,blockChain)
      end


    end

  end


  def createTransactions(count,numTransactions,participants,blockChainPID,mainPID,resultsPID) do
    
    if count < numTransactions do
      receive do
        {:startTransaction} -> #IO.puts "................Initiating transaction #{count + 1}................"
                              pair = Enum.to_list(pairs(2,participants,MapSet.new()))
                              sender_pid = Wallet.findPID(Enum.at(pair,0))
                              receiver_pid = Wallet.findPID(Enum.at(pair,1))
                              
                              Wallet.transaction(sender_pid,receiver_pid)
        
                              createTransactions(count  ,numTransactions,participants,blockChainPID,mainPID,resultsPID)

        {:transactionCompleted,[updated_sender_bitcoins,updated_receiver_bitcoins,sender_details,receiver_details,msgt_hash,resultsPID]} -> 
                                  # IO.puts "Payment successfully processed !!!"
                                  # IO.puts "Sender's wallet balance after successful transaction: #{Float.round(updated_sender_bitcoins,2)}"
                                  # IO.puts "Receiver's wallet balance after successful transaction: #{Float.round(updated_receiver_bitcoins,2)}" 

                                  # IO.puts "\n"
                                  [{_, results}] = :ets.lookup(:user_lookup, "results")
                                  putResults(sender_details,receiver_details,msgt_hash,updated_sender_bitcoins,updated_receiver_bitcoins,count + 1,results)
                                  :timer.sleep(200)
                                  send self(),{:startTransaction}
                                  createTransactions(count + 1 ,numTransactions,participants,blockChainPID,mainPID,resultsPID)
                              
      end
    else
      # blockChain = BlockChain.getBlockChain(blockChainPID)
      # blockChainLength = length(blockChain)
      [{_, results}] = :ets.lookup(:user_lookup, "results")
      wallets = Enum.reduce(Enum.to_list(1..participants),[],fn(x,acc)->
        walletpid = Wallet.findPID(x)
        wallet = Wallet.getWallet(walletpid)
        acc = acc ++ [Float.round(Map.get(wallet,"Bitcoins"),2)]
        # acc = acc ++ [Float.round(:random.uniform()*10,2)]
       end)
      send resultsPID,{:details,[results,wallets]}
      send mainPID,{:completed}
      # IO.puts "Final block chain: #{inspect(blockChain)}"
      # IO.puts "\n"
      # IO.puts "All the transactions have been completed successfully !!!"
    end 
    
  end

  def putResults(sender_details,receiver_details,newBlockHash,updated_sender_bitcoins,updated_receiver_bitcoins,transaction,results) do
    transactiondetails = %{"SenderDetails"=>sender_details, "ReceiverDetails"=>receiver_details,"newBlockHash"=>newBlockHash,"UpdatedSenderBTC"=>updated_sender_bitcoins,"UpdatedReceiverBTC"=>updated_receiver_bitcoins}
    results = Map.put(results,transaction,transactiondetails)
    :ets.insert(:user_lookup, {"results", results})
   end


end
