


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
        require(self.argueFromInvestor || self.argueFromWorker, "Only moderator can call this method");
    }

}




