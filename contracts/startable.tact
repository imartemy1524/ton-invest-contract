

trait Startable with Performable, Investable{
    started: Bool;
    investor: Address;
    performer: Address;
    revokedAt: Int;

    //start the contract
    receive("start"){
        self.requirePerformer();
        self.requireNotCanceled();
        self.started = true;
        self.reply("ok".asComment());
    }
    //cancel the contract before it starts
    receive("cancel"){
        self.requireInvestor();
        self.requireNotStarted();
        self.requireNotCanceled();
        self.releaseFundsToInvestor();
    }
    virtual fun releaseFundsToInvestor(){}

    inline fun requireNotCanceled(){
        require(self.revokedAt == 0, "Contract is canceled");
    }
    inline fun requireCanceled(){
        require(self.revokedAt != 0, "Contract is not canceled");
    }


    inline fun requireStarted(){
        require(self.started, "Contract is not started yet");
    }
    inline fun requireNotStarted(){
        require(!self.started, "Contract is already started");
    }

}



