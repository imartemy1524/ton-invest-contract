
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    excess_to: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}



trait JettonsSender{
    virtual const ModeratorFee: Int = 50;
    subtasks: Subtasks;
    moderator: Address;
    inline fun requireSendFee(sendProfitToOurselfs: Bool){
        require(context().value >= (sendProfitToOurselfs?ton("0.25"):ton("0.13")), "Not enough funds");
    }

    fun sendJettonsTo(to: Address, amount: Int, excessTo: Address, sendProfitToOurselfs: Bool){
        if(sendProfitToOurselfs){
            let outProfitAmount = amount / self.ModeratorFee;
            send(SendParameters{
                to: self.subtasks.token,
                body: TokenTransfer{
                    queryId: 0,
                    amount: amount - outProfitAmount,
                    destination: to,
                    excess_to: excessTo,
                    custom_payload: null,
                    forward_ton_amount: 1,
                    forward_payload: "\x00\x00\x00\x00Jettons sent".asSlice()
                }.toCell(),
                bounce: true,
                value: ton("0.12")
            });
            send(SendParameters{
                to: self.subtasks.token,
                body: TokenTransfer{
                    queryId: 0,
                    amount: outProfitAmount,
                    destination: self.moderator,
                    excess_to: excessTo,
                    custom_payload: null,
                    forward_ton_amount: 1,
                    forward_payload: "\x00\x00\x00\x00Jettons sent".asSlice()
                }.toCell(),
                bounce: true,
                value: ton("0.12")
            });
        }
        else{
            self.forward(
                self.subtasks.token,
                TokenTransfer{
                    queryId: 0,
                    amount,
                    destination: to,
                    excess_to: excessTo,
                    custom_payload: null,
                    forward_ton_amount: 1,
                    forward_payload: "\x00\x00\x00\x00Jettons sent".asSlice()
                }.toCell(),
                true,
                null
            );
        }

    }

    fun restValue(): Int{
        let curr = self.subtasks.finishAmount;
        let tasks = self.subtasks.tasks;
        foreach(key, task in tasks){
            if(!task.finished){
                curr += task.amount;
            }
        }
        return curr;
    }



}