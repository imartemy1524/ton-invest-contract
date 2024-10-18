import { toNano } from '@ton/core';
import { TonInvestor } from '../wrappers/TonInvestor';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const tonInvestor = provider.open(await TonInvestor.fromInit(BigInt(Math.floor(Math.random() * 10000))));

    await tonInvestor.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(tonInvestor.address);

    console.log('ID', await tonInvestor.getId());
}
