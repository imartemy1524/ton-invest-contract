import { NetworkProvider } from '@ton/blueprint';
import { TonGuarantee } from '../build/TonGuarantee/tact_TonGuarantee';
import { toNano } from '@ton/core';


export async function run(provider: NetworkProvider){
    const ui = provider.ui();

    const nft = await ui.inputAddress("Enter NFT address: ");

    const lock = provider.open(TonGuarantee.fromAddress(nft));

    await lock.send(
        provider.sender(),
        {
            value: toNano('0.25'),
            bounce: false
        },
        {
            $$type: 'ReleaseSubtask',
            taskId: 0n,
            isLastTask: false
        }
    );
}