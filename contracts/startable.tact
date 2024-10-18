

trait Startable with Performable, Investable{
    started: Bool;
    canceled: Bool;
    investor: Address;
    performer: Address;
    subtasks: Subtasks;

    //start the contract
    receive("start"){
        self.requirePerformer();
        self.requireNotCanceled();
        self.started = true;
        self.reply("ok".asComment());
    }
    //cancel the contract before it starts
    receive("cancel"){
        self.requireNotStarted();
        self.requireNotCanceled();
        self.canceled = true;
        self.releaseFundsToInvestor();
    }
    abstract fun releaseFundsToInvestor();

    inline fun requireNotCanceled(){
        require(!self.canceled, "Contract is canceled");
    }
    inline fun requireCanceled(){
        require(self.canceled, "Contract is not canceled");
    }


    inline fun requireStarted(){
        require(self.started, "Contract is not started yet");
    }
    inline fun requireNotStarted(){
        require(!self.started, "Contract is already started");
    }

}



