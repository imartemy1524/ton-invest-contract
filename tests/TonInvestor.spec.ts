import { Blockchain, printTransactionFees, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, beginCell, Cell, Dictionary, Slice, toNano } from '@ton/core';
import { OneTask, storeNotifyMessage, storeRandomHasher, storeSubtasks, TonGuarantee } from '../wrappers/TonGuarantee';
import '@ton/test-utils';
import { JettonMaster } from '../build/TonJetton/tact_JettonMaster';
import { JettonChild } from '../build/TonJetton/tact_JettonChild';
import { Collection } from '../build/TonGuarantee/tact_Collection';

async function deployJetton(blockchain: Blockchain, owner: SandboxContract<TreasuryContract>) {
    let jettonMaster = blockchain.openContract(
        await JettonMaster.fromInit(owner.address, Cell.EMPTY, toNano('10000000')),
    );

    // Mint
    await jettonMaster.send(
        owner.getSender(),
        { value: toNano('1') },
        {
            $$type: 'Mint',
            amount: toNano('10000000'),
            receiver: owner.address,
        },
    );

    expect(await jettonMaster.getOwner()).toEqualAddress(owner.address);
    expect(await jettonMaster.getGetJettonData().then((e) => e.totalSupply)).toEqual(toNano('10000000'));
    return jettonMaster;
}

// function randomId(from: Address, tokenAddress: Address, randomId: bigint) {
//     const hashBits = beginCell()
//         .store(
//             storeRandomHasher({
//                 from,
//                 randomId,
//                 sender: tokenAddress,
//                 $$type: 'RandomHasher',
//             }),
//         )
//         .asCell()
//         .hash();
//     return BigInt('0x' + hashBits.toString('hex'));
// }

const interest = (oldAmount: bigint) => oldAmount / 50n;
describe('TonInvestor', () => {
    let blockchain: Blockchain;
    //users
    let investor: SandboxContract<TreasuryContract>;
    let performer: SandboxContract<TreasuryContract>;
    let moderator: SandboxContract<TreasuryContract>;
    //lock contract
    let lockContract: SandboxContract<TonGuarantee>;
    //token contracts
    let tokenMaster: SandboxContract<JettonMaster>;
    let lockToken: SandboxContract<JettonChild>;
    let investorToken: SandboxContract<JettonChild>;
    let performerToken: SandboxContract<JettonChild>;
    let moderatorToken: SandboxContract<JettonChild>;
    //tasks
    let tasks: Dictionary<number, OneTask> = Dictionary.empty();
    const amountAfterFinish: bigint = toNano('1000');

    const totalTokens = () => tasks
            .values()
            .map((e) => e.amount)
            .reduce((a, b) => a + b, 0n) + amountAfterFinish;
    beforeEach(async () => {
        //initialize tasks
        {
            for (let i = 0; i < 10; i++) {
                tasks.set(i, {
                    amount: BigInt(Math.floor(Number(toNano('100')) * Math.random())),
                    $$type: 'OneTask',
                    finished: false,
                });
            }
        }
        //initialize blockchain and users
        {
            blockchain = await Blockchain.create();
            investor = await blockchain.treasury('deployer');
            performer = await blockchain.treasury('performer');
            moderator = await blockchain.treasury('moderator');
            tokenMaster = await deployJetton(blockchain, investor);
        }

        const collection = blockchain.openContract(await Collection.fromInit());

        await collection.send(
            moderator.getSender(),
            {
                value: toNano('0.1'),
            },
            'deploy',
        );
        const collectionJetton = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(collection.address)),
        );
        const randomID = BigInt(Math.floor(Math.random() * 10000000000));

        lockContract = blockchain.openContract(
            await TonGuarantee.fromInit(
                collection.address,
                await collection.getRandomIdFor(collectionJetton.address,investor.address, randomID),
            ),
        );
        //TODO: add check for checking if lock contract is already deployed

        investorToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(investor.address)),
        );
        const { transactions } = await investorToken.send(
            investor.getSender(),
            {
                value: toNano('0.3'),
            },
            {
                $$type: 'TokenTransfer',
                queryId: 0n,
                amount: totalTokens(),
                destination: collection.address,
                response_destination: investor.address,
                custom_payload: null,
                forward_ton_amount: toNano('0.2'),
                forward_payload: beginCell()
                    .storeRef(
                        beginCell().store(
                            storeNotifyMessage({
                                $$type: 'NotifyMessage',
                                randomId: randomID,
                                subtasks: {
                                    $$type: 'Subtasks',
                                    token: await tokenMaster.getGetWalletAddress(lockContract.address),
                                    finishAmount: amountAfterFinish,
                                    tasks,
                                },
                                moderator: moderator.address,
                                performer: performer.address,
                            }),
                        ),
                    )
                    .endCell()
                    .asSlice(),
            },
        );
        printTransactionFees(transactions);
        performerToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(performer.address)),
        );
        moderatorToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(moderator.address)),
        );
        lockToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(lockContract.address)),
        );
    });

    it('should deploy', async () => {
        const { balance } = await lockToken.getGetWalletData();
        expect(balance).toBe(totalTokens());
        const data = await lockContract.getData();
        expect(data.subtasks.tasks.keys().join(',')).toEqual(tasks.keys().join(','));
        expect(data.subtasks.finishAmount).toBe(amountAfterFinish);
        expect(data.subtasks.token).toEqualAddress(await tokenMaster.getGetWalletAddress(lockContract.address));

        expect(data.investor).toEqualAddress(investor.address);
        expect(data.performer).toEqualAddress(performer.address);
        expect(data.moderator).toEqualAddress(moderator.address);
        expect(data.argueFromWorker).toBe(false);
        expect(data.argueFromInvestor).toBe(false);
        expect(data.canceled).toBe(false);
        expect(data.started).toBe(false);

    });
    it('should start', async () => {
        await lockContract.send(
            performer.getSender(),
            {
                value: toNano('0.1'),
            },
            'start',
        );
        const data = await lockContract.getData();
        expect(data.started).toBe(true);
    });
    it('should not start if not performer', async () => {
        await lockContract.send(
            investor.getSender(),
            {
                value: toNano('0.1'),
            },
            'start',
        );
        const data = await lockContract.getData();
        expect(data.started).toBe(false);
    });
    it('investor should cancel', async () => {
        const startBalance = await investorToken.getGetWalletData().then((e) => e.balance);
        const { transactions } = await lockContract.send(
            investor.getSender(),
            {
                value: toNano('0.18'),
            },
            'cancel',
        );
        printTransactionFees(transactions);
        const data = await lockContract.getData();
        expect(data.canceled).toBe(true);
        expect(await investorToken.getGetWalletData().then((e) => e.balance)).toBe(startBalance + totalTokens());
    });
    it('performer should complete tasks', async () => {
        await lockContract.send(
            performer.getSender(),
            {
                value: toNano('0.1'),
            },
            'start',
        );
        let performerBalance = 0n;
        let interestBalance = 0n;
        for (const taskId of tasks.keys()) {
            const isLastTask = await lockContract
                .getData()
                .then((e) => e.subtasks.tasks.values().filter((e) => !e.finished).length === 1);
            await lockContract.send(
                investor.getSender(),
                {
                    value: toNano('0.3'),
                },
                {
                    $$type: 'ReleaseSubtask',
                    taskId: BigInt(taskId),
                    isLastTask,
                },
            );
            const amount = tasks.get(taskId)!.amount;
            interestBalance += interest(amount);
            performerBalance += amount - interest(amount);
            if (isLastTask) {
                performerBalance += amountAfterFinish - interest(amountAfterFinish);
                interestBalance += interest(amountAfterFinish);
            }
            const performerBalanceNow = await performerToken.getGetWalletData().then((e) => e.balance);
            expect(performerBalanceNow).toBe(performerBalance);
            const interestBalanceNow = await moderatorToken.getGetWalletData().then((e) => e.balance);
            expect(interestBalanceNow).toBe(interestBalance);
        }
    });

    it('should argue', async () => {
        await lockContract.send(
            performer.getSender(),
            {
                value: toNano('0.1'),
            },
            'start',
        );
        let performerBalance = 0n;
        const keys = tasks.keys();
        for (let i = 0; i < 5; i++) {
            const taskId = keys[i];
            const isLastTask = await lockContract
                .getData()
                .then((e) => e.subtasks.tasks.values().filter((e) => !e.finished).length === 1);
            const { transactions } = await lockContract.send(
                investor.getSender(),
                {
                    value: toNano('0.25'),
                },
                {
                    $$type: 'ReleaseSubtask',
                    taskId: BigInt(taskId),
                    isLastTask: false,
                },
            );
            let am = tasks.get(taskId)!.amount;
            performerBalance += am - interest(am);
            if (isLastTask) {
                performerBalance += amountAfterFinish - interest(amountAfterFinish);
            }
            const performerBalanceNow = await performerToken.getGetWalletData().then((e) => e.balance);
            expect(performerBalanceNow).toBe(performerBalance);
        }
        //argue

        await lockContract.send(
            investor.getSender(),
            {
                value: toNano('0.19'),
            },
            {
                $$type: 'SetArgue',
                argue: true,
            },
        );
        let data = await lockContract.getData();
        expect(data.argueFromInvestor).toBe(true);
        expect(data.argueFromWorker).toBe(false);
        await lockContract.send(
            moderator.getSender(),
            {
                value: toNano('0.27'),
            },
            {
                $$type: 'ModeratorCloseTask',
                taskId: BigInt(6),
                isLastTask: false,
            },
        );
        const performerBalanceNow = await performerToken.getGetWalletData().then((e) => e.balance);
        expect(performerBalanceNow).toBe(performerBalance + tasks.get(6)!.amount - interest(tasks.get(6)!.amount));
        const investorBalance = await investorToken.getGetWalletData().then((e) => e.balance);
        const { transactions } = await lockContract.send(
            moderator.getSender(),
            {
                value: toNano('0.19'),
            },
            'moderator_cancel',
        );
        data = await lockContract.getData();
        const investorReturnBalance =
            data.subtasks.tasks
                .values()
                .filter((e) => !e.finished)
                .map((e) => e.amount)
                .reduce((a, b) => a + b, 0n) + data.subtasks.finishAmount;
        expect(await investorToken.getGetWalletData().then((e) => e.balance)).toBe(
            investorBalance + investorReturnBalance,
        );
        expect(data.canceled).toBe(true);
    });
});
