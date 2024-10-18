// Jetton transfer payloads
const TYPE_ADD_OFFER: Int = 1;
const TYPE_START_JETTON: Int = 2;
const TYPE_REDEEM: Int = 3;
const TYPE_REDEEM_NOT_REPAYED: Int = 4;

// Error codes

const NoJetton: Int = 0x1001;



struct Loan {
    //Neede Amount
    wantAmount: Int as uint64;
    //Loan duration in days
    days: Int as uint8;
    //In tons
    dayInterest: Int as uint64;
    jetton: Address?;
}
//message NewLoan {
//    senderAddress: Address;
//    op: Int as uint32;
//    queryId: Int as uint64;
//    prevOwnerAddress: Address;
//
//    forwardPayload: Loan as remaining;
//
//}


message(0x1284273) InitLoan {
    //    queryId: Int as uint64;
    loan: Loan;
    nftAddress: Address;
    owner: Address;
}

message(0x8122548) StartMsg{}
message(0x9dad60b2) Offer {
    offerLoan: Loan;
}
struct OfferLoan{
    offer: Loan;
    owner: Address;
}
message(0x12925382) WithdrawNFTNotRepayed{}
message(0x12915486) CancelLoan{}
message(0x21472373) RedeemMessage{}
message(0x3c576c66) CancelOffer{
    offerIndex: Int;
}
message(0x6cd2612c) StartOfferIndex{
    offerIndex: Int;
}
struct ForwardNftPayload{
    loan: Loan;
}

message(0x28361849) SetAcceptableJettons{
    jettons: map<Address,Address>;
}
message(0x05138d91) OwnershipAssignedMaster {
    queryId: Int as uint64;
    prevOwner: Address;
    bite: Bool;
    //REQUIRED to pass loan as payload!!!
    payload: Slice as remaining;
}
message(0x19274626) TransferNftToLoan {
    nft: Address;
    excessTo: Address;
    myId: Int as uint64;
}
message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}
message(0x19487234) WithdrawlToken{
    amount: Int as coins;
    myJetton: Address?;
}
message(0x5fcc3d14) TransferNFT {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Bool;

    forwardAmount: Int as coins;
    hasPayload: Bool;
    forwardPayload: Slice as remaining;
}
message(0xd53276db) ExcessMsg{}
message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_ton_amount: Int as coins;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

struct LoanData{
    nft: Address?;
    owner: Address;
    stopped: Bool;
    parent: Address;
    started: Bool;
    loanIssuer: Address?;
    activeLoan: Loan;
    // Return the index of the master contract. With it one can easily verify, that this contract really belongs to the master (call master getContract).
    masterIndex: Int as uint64;
    startTime: Int as uint64;
    accuredInterest: Int as uint64;
    merchantInterest: Int as uint64;
    acceptJettons: map<Address, Address>;
}

//extends fun toInt(self: String, skip: Int): Int {
//
//    // Cast the String as a Slice for parsing
//    let string: Slice = self.asSlice();
//    string.loadBits(8 * skip);
//
//    // A variable to store the accumulated number
//    let acc: Int = 0;
//
//    // Loop until the String is empty
//    while (!string.empty()) {
//        let char: Int = string.loadUint(8); // load 8 bits (1 byte) from the Slice
//        acc = (acc * 10) + (char - 48);     // using ASCII table to get numeric value
//        // Note, that this approach would produce unexpected results
//        //   when the starting String contains non-numeric characters!
//    }
//
//    // Produce the resulting number
//    return acc;
//}
//extends fun startsWith(self: String, what: String): Bool{
//    let whatSlice: Slice = what.asSlice();
//    let selfSlice: Slice = self.asSlice();
//    let whatLen: Int = whatSlice.bits()/8;
//    let selfLen: Int = selfSlice.bits()/8;
//    if (whatLen > selfLen) {
//        return false;
//    }
//    while(whatLen > 0) {
//        if (whatSlice.loadUint(8) != selfSlice.loadUint(8)) {
//            return false;
//        }
//        whatLen = whatLen - 1;
//    }
//
//    return true;
//}
fun requireOrReturn(condition: Bool, code: Int){
    if (!condition){
        throw(code);
    }
}



message(0x7362d09c) TokenRecievedMessage {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    type: Int as uint8;
    data: Slice as remaining;
}

//message(0x7362d09c) TokenRecievedStart {
//    queryId: Int as uint64;
//    amount: Int as coins;
//    from: Address;
//    ignore: Bool;
//}
const Excess: ExcessMsg = ExcessMsg{} ;


