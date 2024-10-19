import { Blockchain, printTransactionFees, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, beginCell, Cell, Dictionary, Slice, toNano } from '@ton/core';
import { OneTask, storeSubtasks, TonInvestor } from '../wrappers/TonInvestor';
import '@ton/test-utils';
import { JettonMaster } from '../build/TonJetton/tact_JettonMaster';
import { JettonChild } from '../build/TonJetton/tact_JettonChild';

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

describe('TonInvestor', () => {
    let blockchain: Blockchain;
    //users
    let investor: SandboxContract<TreasuryContract>;
    let performer: SandboxContract<TreasuryContract>;
    let moderator: SandboxContract<TreasuryContract>;
    //lock contract
    let lockContract: SandboxContract<TonInvestor>;
    //token contracts
    let tokenMaster: SandboxContract<JettonMaster>;
    let lockToken: SandboxContract<JettonChild>;
    let investorToken: SandboxContract<JettonChild>;
    let performerToken: SandboxContract<JettonChild>;
    //tasks
    let tasks: Dictionary<number, OneTask>;
    const amountAfterFinish: bigint = toNano('1000');

    const totalTokens = () => tasks
            .values()
            .map((e) => e.amount)
            .reduce((a, b) => a + b, 0n) + amountAfterFinish;
    beforeEach(async () => {
        blockchain = await Blockchain.create();

        investor = await blockchain.treasury('deployer');
        performer = await blockchain.treasury('performer');
        moderator = await blockchain.treasury('moderator');

        lockContract = blockchain.openContract(
            await TonInvestor.fromInit(investor.address, performer.address, moderator.address),
        );

        tokenMaster = await deployJetton(blockchain, investor);
        investorToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(investor.address)),
        );
        performerToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(performer.address)),
        );
        lockToken = blockchain.openContract(
            JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(lockContract.address)),
        );

        tasks = Dictionary.empty();
        for (let i = 0; i < 10; i++) {
            tasks.set(i, {
                amount: BigInt(Math.floor(Number(toNano('100')) * Math.random())),
                $$type: 'OneTask',
                finished: false,
            });
        }

        const deployResult = await lockContract.send(
            investor.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'IntializeContract',
                subtasksIT: {
                    $$type: 'Subtasks',
                    token: await tokenMaster.getGetWalletAddress(lockContract.address),
                    finishAmount: amountAfterFinish,
                    tasks,
                },
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: investor.address,
            to: lockContract.address,
            deploy: true,
            success: true,
        });

        const { transactions } = await investorToken.send(
            investor.getSender(),
            {
                value: toNano('1.05'),
            },
            {
                $$type: 'TokenTransfer',
                amount: totalTokens(),
                queryId: 0n,
                destination: lockContract.address,
                response_destination: investor.address,
                custom_payload: null,
                forward_ton_amount: 1n,
                forward_payload: beginCell()
                    .storeUint(0, 32)
                    .storeStringTail('Send funds for lock')
                    .endCell()
                    .asSlice(),
            },
        );
    });

    it('should deploy', async () => {
        const { balance } = await lockToken.getGetWalletData();
        expect(balance).toBe(totalTokens());
        const data = await lockContract.getData();
        expect(beginCell().store(storeSubtasks(data.subtasks)).endCell()).toEqualCell(
            beginCell()
                .store(
                    storeSubtasks({
                        $$type: 'Subtasks',
                        tasks,
                        finishAmount: amountAfterFinish,
                        token: await tokenMaster.getGetWalletAddress(lockContract.address),
                    }),
                )
                .endCell(),
        );
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
        await lockContract.send(
            investor.getSender(),
            {
                value: toNano('0.15'),
            },
            'cancel',
        );
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
        for (const taskId of tasks.keys()) {
            const isLastTask = await lockContract
                .getData()
                .then((e) => e.subtasks.tasks.values().filter((e) => !e.finished).length === 1);
            await lockContract.send(
                investor.getSender(),
                {
                    value: toNano('0.19'),
                },
                {
                    $$type: 'ReleaseSubtask',
                    taskId: BigInt(taskId),
                    isLastTask,
                },
            );
            performerBalance += tasks.get(taskId)!.amount;
            if (isLastTask) {
                performerBalance += amountAfterFinish;
            }
            const performerBalanceNow = await performerToken.getGetWalletData().then((e) => e.balance);
            expect(performerBalanceNow).toBe(performerBalance);
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
            await lockContract.send(
                investor.getSender(),
                {
                    value: toNano('0.19'),
                },
                {
                    $$type: 'ReleaseSubtask',
                    taskId: BigInt(taskId),
                    isLastTask: false,
                },
            );
            performerBalance += tasks.get(taskId)!.amount;
            if (isLastTask) {
                performerBalance += amountAfterFinish;
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
                value: toNano('0.19'),
            },
            {
                $$type: 'ModeratorCloseTask',
                taskId: BigInt(6),
                isLastTask: false,
            },
        );
        const performerBalanceNow = await performerToken.getGetWalletData().then((e) => e.balance);
        expect(performerBalanceNow).toBe(performerBalance + tasks.get(6)!.amount);
        const investorBalance = await investorToken.getGetWalletData().then((e) => e.balance);
        const {transactions} = await lockContract.send(
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
