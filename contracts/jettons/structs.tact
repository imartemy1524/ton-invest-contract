// Jetton transfer payloads
const TYPE_ADD_OFFER: Int = 1;
const TYPE_START_JETTON: Int = 2;
const TYPE_REDEEM: Int = 3;
const TYPE_REDEEM_NOT_REPAYED: Int = 4;

// Error codes

const NoJetton: Int = 0x1001;







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


