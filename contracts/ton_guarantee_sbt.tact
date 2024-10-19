message(0x5fcc3d14) NftTransfer {
    queryId: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}
message(0x2fcb26a2) GetStaticData {
    queryId: Int as uint64;
}
message(0x1f04537a) Destroy {
    queryId: Int as uint64;
}
message(0x6f89f5e3) Revoke {
    queryId: Int as uint64;
}

struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address?;
    individual_content: Cell;
}
message(0x8b771735) ReportStaticData {
    queryId: Int as uint64;
    index_id: Int;
    collection: Address;
}
message(0x0524c7ae) OwnershipProof {
    queryId: Int as uint64;
    item_id: Int as uint256;
    owner: Address;
    data: Cell;
    revoked_at: Int as uint64;
    content: Cell?;
}
message(0x04ded148) ProveOwnership {
    queryId: Int as uint64;
    dest: Address;
    forward_payload: Cell;
    with_content: Bool;
}

message(0xc18e86d2) OwnershipProofBounced {
    queryId: Int as uint64;
}


trait TonGuaranteeSbt with Investable, Startable {
    collection: Address;
    investor: Address;
    performer: Address;
    started: Bool;
    revokedAt: Int;
    index: Int;
    receive(m: NftTransfer){
        throw(132);
    }
    receive(msg: GetStaticData){
        require(self.isNftInitialized(), "Not initialized");
        self.reply(ReportStaticData{ queryId: msg.queryId, index_id: self.index, collection: self.collection }.toCell());
        self.exitWithoutSaving();
    }
    receive(msg: ProveOwnership) {
        require(self.isNftInitialized(), "Not initialized");
        self.requireInvestor();
        let content: Cell? = null;
        if (msg.with_content) {
            content = self.getData();
        }
        self.forward(
            msg.dest,
            OwnershipProof {
                queryId: msg.queryId,
                item_id: self.index,
                owner: self.investor,
                data: msg.forward_payload,
                revoked_at: self.revokedAt,
                content
            }.toCell(),
            true, null
        );
        self.exitWithoutSaving();
    }
    get fun get_authority_address(): Cell {
        return beginCell().storeBit(false).storeBit(false).endCell();
    }


    inline fun exitWithoutSaving() {
        commit();
        throw(0);
    }
    get fun get_nft_data(): GetNftData {
        return GetNftData{
            is_initialized: self.isNftInitialized(),
            index: self.index,
            collection_address: self.collection,
            owner_address: self.investor,
            individual_content: self.getData()
        };
    }
    get fun get_revoked_time(): Int {
        return self.revokedAt;
    }


    receive(msg: Destroy) {
        throw(132);
    }
    receive(msg: Revoke) {
        throw(132);
    }
    abstract fun isNftInitialized(): Bool;
    abstract inline fun getData(): Cell;
    bounced(msg: bounced<OwnershipProof>) {
        self.forward(self.investor, OwnershipProofBounced{queryId: msg.queryId}.toCell(), false, null);
        self.exitWithoutSaving();
    }
}