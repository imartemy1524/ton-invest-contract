import { Address, beginCell, Dictionary, toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { Collection } from '../build/TonGuarantee/tact_Collection';
import { OneTask, storeNotifyMessage, TonGuarantee } from '../build/TonGuarantee/tact_TonGuarantee';
import { JettonChild } from '../build/TonJetton/tact_JettonChild';
import { JettonMaster } from '../build/TonJetton/tact_JettonMaster';

export async function run(provider: NetworkProvider, args: string[]) {
    const ui = provider.ui();
    const collection = provider.open(await Collection.fromInit());
    const jettonAddress = await ui.inputAddress(
        'Enter jetton master address:',
        Address.parse('kQAp_H-fVRrcAhNS7LaXGQ4GsP_yBQT98t0kwNohtaUjLg7r'),
    );
    let tasks: Dictionary<number, OneTask> = Dictionary.empty();
    for (let i = 0; i < 5; i++) {
        tasks = tasks.set(i, {
            amount: toNano('0.0001'),
            finished: false,
            $$type: 'OneTask',
        });
    }
    const tokenMaster = provider.open(JettonMaster.fromAddress(jettonAddress));
    const randomId = BigInt(Math.floor(Math.random() * 1000000));
    const collectionJetton = provider.open(
        JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(collection.address)),
    );

    const lockContract = provider.open(
        await TonGuarantee.fromInit(
            collection.address,
            await collection.getRandomIdFor(collectionJetton.address, provider.sender().address!, randomId),
        ),
    );
    const investorToken = provider.open(
        JettonChild.fromAddress(await tokenMaster.getGetWalletAddress(provider.sender().address!)),
    );
    const moderator = Address.parse(args[0]);
    const performer = Address.parse(args[0]);
    console.log('Investor token address: ', investorToken.address.toString());
    await investorToken.send(
        provider.sender(),
        {
            value: toNano('0.3'),
            bounce: true,
        },
        {
            $$type: 'TokenTransfer',
            queryId: 0n,
            amount: toNano('0.0015'),
            destination: collection.address,
            response_destination: provider.sender().address!,
            custom_payload: null,
            forward_ton_amount: toNano('0.2'),
            forward_payload: beginCell()
                .storeBit(1)
                .storeRef(
                    beginCell()
                        .store(
                            storeNotifyMessage({
                                $$type: 'NotifyMessage',
                                randomId,
                                subtasks: {
                                    $$type: 'Subtasks',
                                    token: await tokenMaster.getGetWalletAddress(lockContract.address),
                                    finishAmount: toNano('0.001'),
                                    tasks,
                                },
                                moderator: moderator,
                                performer: performer,
                            }),
                        ),
                )
                .endCell()
                .asSlice(),
        },
    );

    await provider.waitForDeploy(lockContract.address, 100);
}
