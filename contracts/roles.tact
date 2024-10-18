message ModeratorCloseTask{
    taskId: Int as uint64;
}


trait Investable {
    investor: Address;
    inline fun requireInvestor(){
        require(sender() == self.investor, "Only investor can call this method");
    }
}
trait Performable {
    performer: Address;
    inline fun requirePerformer(){
        require(sender() == self.performer, "Only worker can call this method");
    }
}

trait Moderable with Investable, Performable, Arguable {
    moderator: Address;

    // argues
    argueFromInvestor: Bool;
    argueFromWorker: Bool;

    // from investable and workable
    investor: Address;
    performer: Address;

    inline fun requireModerator(){
        require(sender() == self.moderator, "Only moderator can call this method");
        self.requireArgue();
    }




    // moderator sends rest of the funds to investor

    receive(m: ModeratorCloseTask){
        self.requireModerator();
        self.closeTask(m.taskId);
    }
    receive("moderator_cancel"){
        self.requireModerator();
        self.releaseFundsToInvestor();
    }
    abstract fun releaseFundsToInvestor();
    abstract fun closeTask(taskId: Int);
}




