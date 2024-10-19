message SetArgue{
    argue: Bool;
}


trait Arguable with Investable, Performable {
    investor: Address;
    performer: Address;
    argueFromInvestor: Bool;
    argueFromWorker: Bool;

    receive(m: SetArgue){
        if(sender() == self.investor){
            self.argueFromInvestor = m.argue;
        }
        else if(sender() == self.performer){
            self.argueFromWorker = m.argue;
        }
        else {
            require(false, "Invalid sender");
        }
        self.reply("ok".asComment());
    }

    inline fun requireArgue(){
        require(self.argueFromInvestor || self.argueFromWorker, "No argue");
    }

}
