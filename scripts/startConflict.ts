import { NetworkProvider } from '@ton/blueprint';
import { TonGuarantee } from '../build/TonGuarantee/tact_TonGuarantee';
import { toNano } from '@ton/core';

export async function run(provider: NetworkProvider) {
    const ui = provider.ui();
    const nft = await ui.inputAddress('Enter NFT address: ');

    const lock = provider.open(TonGuarantee.fromAddress(nft));

    await lock.send(
        provider.sender(),
        {
            value: toNano('0.02'),
            bounce: false,
        },
        {
            $$type: 'SetArgue',
            argue: await ui.choose('Choose argue', [true, false], (v) => (v ? 'Initialized' : 'Cancel')),
        },
    );
}
