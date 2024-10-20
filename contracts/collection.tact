import "./ton_guarantee.tact";
struct ElString{value: String;}
extends inline fun buildNftName(self: InvestmentData, index: Int): String {
    let builderName = beginString()
        .concat("Investment SBT #")
        .concat(index.toString())
        .toString();
    return builderName;
}
extends inline fun buildDescription(self: InvestmentData, index: Int): String {
    let count = 0;
    let done = 0;
    foreach(a, b in self.subtasks.tasks){
        count += 1;
        if(b.finished){
            done += 1;
        }
    }
    let builderDescription = beginString()
        .concat("Investment for work with ").concat(count.toString()).concat(" subtasks (").concat(done.toString()).concat(" done)").concat(", which is done by ")
        .concat(self.performer.toString())
        .concat(" with 3rd-party moderation by ")
        .concat(self.moderator.toString())
        .toString();
    return builderDescription;
}
extends inline fun buildAttributesString(self: InvestmentData): String {
    let builderAttributes = beginString()
        .concat("[{\"trait_type\":\"Performer\",\"value\":\"")
        .concat(self.performer.toString())
        .concat("\"},{\"trait_type\":\"Moderator\",\"value\":\"")
        .concat(self.moderator.toString())
        .concat("\"}]");
    return builderAttributes.toString();
}
inline extends fun buildImage(self: InvestmentData): ElString {
    return ElString{ value: "https://storage.ronin.co/spa_zbhtcy3dmbx5jzgg/30793843-1ff2-45c4-9c65-f211d674c959"};
}
//Store nft text as snake cell
inline fun nftTextToCellAsMultiref(input: String): Cell {
    let slice: Slice = input.asSlice();

    let builder = beginString()
    //   write "0" as uint
    .concat("\x00")
    //   write input as string (s.t. cell refs would be recalculated)
    .concat(input);
    return builder.toCell();
}
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address?;
}

//https://medium.com/nexton-node/nfts-with-on-chain-metadata-on-ton-tutorial-55ac0cbb17d5#a51c

fun buildData(content: map<Int, ElString>): Cell{
    let ans: map<Int as uint256, Cell> = emptyMap();
    foreach(key, value in content){
        ans.set(key, nftTextToCellAsMultiref(value.value));
    }
    return beginCell().storeInt(0, 8).storeBool(true).storeRef(ans.asCell()!!).endCell();
}


trait SbtCollection{
    abstract const CollectionName: String;
    abstract const CollectionDescription: String;
    abstract const LogoURL: String;

    get fun get_collection_data(): CollectionData {
        let data: map<Int, ElString> = emptyMap();
        data.set(sha256("name"), ElString{ value: self.CollectionName});
        data.set(sha256("description"), ElString{ value: self.CollectionDescription});
        data.set(sha256("image"), ElString{value: self.LogoURL});
        //        data.set( sha256("image"), ElString{ value: self.LogoURL});
//        data.set(sha256("marketplace"), ElString{ value: self.MartketplaceURL});
        return CollectionData{
            next_item_index: -1,
            collection_content: buildData(data),
                owner_address: NullAddress,
        };
    }
    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        let content: InvestmentData = InvestmentData.fromCell(individual_content);
        let data: map<Int, ElString> = emptyMap();

        data.set(sha256("name"), ElString{value: content.buildNftName(index)});
        data.set(sha256("image"), content.buildImage());
        data.set(sha256("description"), ElString{ value: content.buildDescription(index)});
        data.set(sha256("attributes"), ElString{ value: content.buildAttributesString()});
        let ans = buildData(data);
        return ans;
    }
    get fun get_nft_address_by_index(index: Int): Address {
        return self.at(index);
    }

    abstract inline fun at(index: Int): Address;

}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

struct NotifyMessage{
    performer: Address;
    moderator: Address;
    randomId: Int;
    subtasks: Subtasks;
}
struct RandomHasher{
    jetton: Address;
    investor: Address;
    randomId: Int;
}

contract Collection with SbtCollection{
    override const CollectionName: String = "Investments SBTs";
    override const CollectionDescription: String = "Collection of SBT-based investments. Each NFT represents a single investment";
    override const LogoURL: String = "https://storage.ronin.co/spa_zbhtcy3dmbx5jzgg/30793843-1ff2-45c4-9c65-f211d674c959";
    override const storageReserve: Int = ton("0.02");

    override inline fun at(id: Int): Address{
        return contractAddress(initOf TonGuarantee(myAddress(), id));
    }


    receive(m: TokenNotification){
        require(context().value >= ton("0.2"), "Not enough value");
        let ok: NotifyMessage = NotifyMessage.fromCell(m.forward_payload.loadRef());
        let am = ok.subtasks.finishAmount;
        foreach(_, a in ok.subtasks.tasks){
            am += a.amount;
        }
        require(m.amount >= am, "Incorrect amount sent");
        let id = self._randomIdFor(sender(), m.from, ok.randomId);
        let data = initOf TonGuarantee(
            myAddress(),
            id
        );
        let to = contractAddress(data);
        send(SendParameters{
            to,
            body: InitializeContract{
                investor: m.from,
                moderator: ok.moderator,
                performer: ok.performer,
                subtasks: ok.subtasks
            }.toCell(),
            bounce: false,
            data: data.data,
            code: data.code,
            value: ton("0.05")
        });
        send(SendParameters{
            to: sender(),
            body: TokenTransfer{
                queryId: 0,
                amount: m.amount,
                destination: to,
                excess_to: m.from,
                custom_payload: null,
                forward_ton_amount: 1,
                forward_payload: "\x00\x00\x00\x00Jettons sent".asSlice()
            }.toCell(),
            bounce: true,
            value: ton("0.14")
        });
    }
    receive("deploy"){
        self.reply("ok".asComment());
    }

    get fun randomIdFor(jetton: Address, investor: Address, randomId: Int): Int{
        return self._randomIdFor(jetton, investor, randomId);
    }

    fun _randomIdFor(jetton: Address, investor: Address, randomId: Int): Int{
        return RandomHasher{
        jetton,
        investor,
        randomId
        }.toCell().hash();
    }
}



