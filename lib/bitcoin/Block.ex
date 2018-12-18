defmodule BlockChain do
    use GenServer
    
    def start_link() do
        {:ok,pid} = GenServer.start_link(__MODULE__,[])
        pid
    end

    def init([]) do
        state = zeroBlock([])
        {:ok,state}
    end

    def zeroBlock(state) do
        zeroBlock = %{
            transactionData: %{"bitcoins"=>0,"receiverPublicKey"=>""},
            prev_hash: "zero_block",
            hash: "zero_block",
            signedMessage: "first_RSA",
            timestamp: NaiveDateTime.utc_now,
            senderPublicKey: "",
          }
        state = state ++ [zeroBlock]
        state
    end

    def handle_cast({:changeBlockChain,blockChain},state) do
        state = blockChain
        {:noreply,state}
    end

    def getBlockChain(pid) do
        GenServer.call(pid,{:getBlockChain})
    end

    def changeBlockChain(pid, blockChain) do
        GenServer.cast(pid,{:changeBlockChain,blockChain})
    end

    def handle_call({:getBlockChain},_from,state) do
        {:reply,state,state}         
    end

    
end