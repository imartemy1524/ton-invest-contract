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
message InitializeContract{
    investor: Address;
    moderator: Address;
    performer: Address;
    subtasks: Subtasks;

}
message ReleaseSubtask{
    taskId: Int;
    isLastTask: Bool;
}
const NullAddress: Address = address("UQD__________________________________________xYt");

struct InvestmentData{
    subtasks: Subtasks;
    investor: Address;
    performer: Address;
    moderator: Address;
    argueFromInvestor: Bool;
    argueFromWorker: Bool;
    started: Bool;
    canceled: Bool;
    index: Int;
}