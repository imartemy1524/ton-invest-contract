import "@stdlib/deploy";
import "./roles.tact";
import "./arguable.tact";
import "./startable.tact";
import "./jettons_sender.tact";
import "./structs.tact";
contract TonGuarantee with Moderable, Startable, JettonsSender {
    override const storageReserve: Int = ton("0.01");
    argueFromInvestor: Bool = false;
    argueFromWorker: Bool = false;
    started: Bool = false;
    canceled: Bool = false;

    investor: Address;
    performer: Address;
    moderator: Address;
    subtasks: Subtasks;

    collection: Address;
    index: Int;

    init(collection: Address, index: Int) {
        self.collection = collection;
        self.index = index;
        self.subtasks = Subtasks{ token: NullAddress, tasks: emptyMap(), finishAmount: 0};
        self.investor = NullAddress;
        self.performer = NullAddress;
        self.moderator = NullAddress;
    }

    //message to initialize contract
    receive(m: InitializeContract){
        require(sender() == self.collection, "Only collection can initialize contract");
        try{
            self.requireNotStarted();
            require(self.investor == NullAddress, "Already initialized");
            require(self.performer == NullAddress, "Already initialized");
            require(self.moderator == NullAddress, "Already initialized");
            self.subtasks = m.subtasks;
            self.investor = m.investor;
            self.performer = m.performer;
            self.moderator = m.moderator;
            foreach(key, task in self.subtasks.tasks){
                require(!task.finished, "Can not initialize contract with finished tasks");
            }
            self.forward(m.investor, "ok".asComment(), false, null);
        } catch(e){
            throw(e);
            //TODO: what if error???
        }
    }


    //release the funds to performer
    receive(m: ReleaseSubtask){
        self.requireInvestor();
        self.requireStarted();
        self.requireNotCanceled();
        self.closeTask(m.taskId, m.isLastTask);
    }

    //cancel the contract by performer
    receive("cancel_performer"){
        self.requireSendFee(false);
        self.requirePerformer();
        self.requireNotCanceled();

        self.releaseFundsToInvestor();
    }

    override fun releaseFundsToInvestor(){
        self.canceled = true;
        self.requireSendFee(false);
        self.sendJettonsTo(self.investor, self.restValue(), sender(), false);
    }

    override fun closeTask(taskId: Int, isLastTask: Bool){
        self.requireSendFee(true);
        let task = self.subtasks.tasks.get(taskId);
        require(task != null && !task!!.finished, "Task is not found or already finished");
        let taskNotNull = task!!;
        taskNotNull.finished = true;
        self.subtasks.tasks.set(taskId, taskNotNull);
        let amount = taskNotNull.amount;
        if(isLastTask){
            foreach(_, taskIT in self.subtasks.tasks){
                require(taskIT.finished, "Not all tasks are finished");
            }
            amount += self.subtasks.finishAmount;
        }
        self.sendJettonsTo(self.performer, amount, sender(), true);
    }

    get fun data(): InvestmentData{
        return self._data();
    }

    fun _data(): InvestmentData{
        return InvestmentData{
            subtasks: self.subtasks,
            investor: self.investor,
            performer: self.performer,
            moderator: self.moderator,
            argueFromInvestor: self.argueFromInvestor,
            argueFromWorker: self.argueFromWorker,
            started: self.started,
            canceled: self.canceled,
            index: self.index
        };
    }
}







