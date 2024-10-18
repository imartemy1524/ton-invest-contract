import "@stdlib/deploy";
import "./roles.tact";
import "./arguable.tact";
import "./startable.tact";
import "./jettons_sender.tact";
struct OneTask{
    amount: Int as coins;
    finished: Bool = false;
}
struct Subtasks{
    token: Address;
    // amount that would be send to performer after all tasks are finished
    finsihAmount: Int as coins;
    tasks: map<Int as uint16, OneTask> = emptyMap();
}
message IntializeContract{
    subtasks: Subtasks;
}
message ReleaseSubtask{
    taskId: Int;
}

const NullAddress: Address = address("UQD__________________________________________xYt");
contract TonInvestor with Moderable, Startable, JettonsSender {
    argueFromInvestor: Bool = false;
    argueFromWorker: Bool = false;
    started: Bool = false;
    canceled: Bool = false;

    investor: Address;
    performer: Address;
    moderator: Address;
    subtasks: Subtasks;

    init(investor: Address, performer: Address, moderator: Address) {
        self.investor = investor;
        self.performer = performer;
        self.moderator = moderator;
        self.subtasks = Subtasks{ token: NullAddress, tasks: emptyMap(), finsihAmount: 0};
    }

    receive(m: IntializeContract){
        self.requireNotStarted();
        require(self.subtasks.token == NullAddress, "Already initialized");
        self.requireInvestor();
        self.subtasks = m.subtasks;
        foreach(key, task in self.subtasks.tasks){
            require(!task.finished, "Can not initialize contract with finished tasks");
        }
    }


    //release the funds to performer
    receive(m: ReleaseSubtask){
        self.requireInvestor();
        self.requireStarted();
        self.requireSendFee();
        self.requireNotCanceled();

        let task = self.subtasks.tasks.get(m.taskId);
        require(task != null && !task!!.finished, "Task is not found or already finished");
        let taskNotNull = task!!;
        taskNotNull.finished = true;
        self.subtasks.tasks.set(m.taskId, taskNotNull);
        self.sendJettonsTo(self.performer, taskNotNull.amount, sender());
    }

    //cancel the contract by performer
    receive("cancel_performer"){
        self.requireSendFee();
        self.requirePerformer();
        self.requireNotCanceled();

        self.canceled = true;
        self.sendJettonsTo(self.investor, self.restValue(), sender());
    }

    override fun releaseFundsToInvestor(){
        self.requireSendFee();
        self.sendJettonsTo(self.investor, self.restValue(), sender());

    }
}







