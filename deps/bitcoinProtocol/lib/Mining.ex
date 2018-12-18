defmodule Mining do

    def miner(blockChainPID,blockVerificationPID) do
        blockChain = BlockChain.getBlockChain(blockChainPID)
        currentIndex = length(blockChain)-1
        receive do
            {:ok,[transactionData,signature,sender_PubKey,senderPID,sender_details,receiver_details]} -> mining(blockChainPID,transactionData,signature,sender_PubKey,currentIndex,senderPID,blockVerificationPID,sender_details,receiver_details)
                                                                         miner(blockChainPID,blockVerificationPID)
            # {:updatePointer,[blockChainEndIndex]} -> currentIndex = blockChainEndIndex + 1
            #                                          miner(blockChainPID,blockVerificationPID)
        end
    end

    def mining(blockChainPID,transactionData,signature,sender_PubKey,actualIndex,senderPID,blockVerificationPID,sender_details,receiver_details) do
        blockChain = BlockChain.getBlockChain(blockChainPID)
        currentIndex = length(blockChain)-1
        block = Enum.at(blockChain,length(blockChain)-1)
        hash = Map.get(block, :hash)
        
        msgt_hash = cryptoHash(hash,transactionData)

        if actualIndex == currentIndex do
            if(String.slice(msgt_hash,0,3) === String.duplicate("0",3)) do
                # IO.puts "New block's hash: #{inspect(msgt_hash)}"
                newBlock = %{
                    transactionData: transactionData,
                    prev_hash: hash,
                    hash: msgt_hash,
                    signedMessage: signature,
                    timestamp: NaiveDateTime.utc_now,
                    senderPublicKey: sender_PubKey,
                  }
                  blockChain = blockChain ++ [newBlock]                 
                  BlockChain.changeBlockChain(blockChainPID,blockChain)
                #   send self(), {:updatePointer, [length(blockChain)-1,senderPID]}
                  
                  send blockVerificationPID,{:ok,[senderPID,sender_details,receiver_details,msgt_hash]}
            else
                mining(blockChainPID,transactionData,signature,sender_PubKey,actualIndex,senderPID,blockVerificationPID,sender_details,receiver_details)
            end
        end

        
    end

    def cryptoHash(hash,transactionData) do
        bitcoins = to_string(Map.get(transactionData,"bitcoins"))
        receiver_PK = Map.get(transactionData,"receiverPublicKey")
        msgt = bitcoins <> receiver_PK <> hash <> randomizer(9)
        :crypto.hash(:sha256, msgt) |> Base.encode16 |> String.downcase
    end

    def randomizer(l) do
        :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
    end
end