
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
    subtasks: Subtasks;


    inline fun requireSendFee(){
        require(context().value >= ton("0.13"), "Not enough funds");
    }

    fun sendJettonsTo(to: Address, amount: Int, excessTo: Address){
        self.forward(
            self.subtasks.token,
            TokenTransfer{
                queryId: 0,
                amount,
                destination: to,
                excess_to: excessTo,
                custom_payload: null,
                forward_ton_amount: 1,
                forward_payload: beginString()
                    .concat("\x00\x00\x00\x00")
                    .concat("Jettons sent")
                    .toString().asSlice()
            }.toCell(),
            true,
            null
        );
    }

    fun restValue(): Int{
        let curr = self.subtasks.finsihAmount;
        foreach(key, task in self.subtasks.tasks){
            if(!task.finished){
                curr += task.amount;
            }
        }
        return curr;
    }
}