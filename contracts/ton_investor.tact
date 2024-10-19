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
    finishAmount: Int as coins;
    tasks: map<Int as uint16, OneTask>;
}
message IntializeContract{
    subtasksIT: Subtasks;
}
message ReleaseSubtask{
    taskId: Int;
    isLastTask: Bool;
}
const NullAddress: Address = address("UQD__________________________________________xYt");

struct InvestmentData{
    investor: Address;
    performer: Address;
    moderator: Address;
    subtasks: Subtasks;
    argueFromInvestor: Bool;
    argueFromWorker: Bool;
    started: Bool;
    canceled: Bool;
}
contract TonInvestor with Moderable, Startable, JettonsSender {
    override const storageReserve: Int = ton("0.01");
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
        self.subtasks = Subtasks{ token: NullAddress, tasks: emptyMap(), finishAmount: 0};
    }

    //message to initialize contract
    receive(m: IntializeContract){
        self.requireNotStarted();
        require(self.subtasks.token == NullAddress, "Already initialized");
        self.requireInvestor();
        self.subtasks = m.subtasksIT;
        foreach(key, task in self.subtasks.tasks){
            require(!task.finished, "Can not initialize contract with finished tasks");
        }
        self.reply("deployed".asComment());
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
        self.requireSendFee();
        self.requirePerformer();
        self.requireNotCanceled();

        self.releaseFundsToInvestor();
    }

    override fun releaseFundsToInvestor(){
        self.canceled = true;
        self.requireSendFee();
        self.sendJettonsTo(self.investor, self.restValue(), sender());
    }

    override fun closeTask(taskId: Int, isLastTask: Bool){
        self.requireSendFee();
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
        self.sendJettonsTo(self.performer, amount, sender());
    }

    get fun data(): InvestmentData{
        return InvestmentData{
            investor: self.investor,
            performer: self.performer,
            moderator: self.moderator,
            subtasks: self.subtasks,
            argueFromInvestor: self.argueFromInvestor,
            argueFromWorker: self.argueFromWorker,
            started: self.started,
            canceled: self.canceled
        };
    }
}







