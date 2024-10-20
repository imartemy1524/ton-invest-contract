import { toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { Collection } from '../build/TonGuarantee/tact_Collection';

export async function run(provider: NetworkProvider) {
    const tonInvestor = provider.open(await Collection.fromInit());

    await tonInvestor.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        'deploy'
    );

    await provider.waitForDeploy(tonInvestor.address);

    console.log('Collection ', tonInvestor.address.toString());
}
