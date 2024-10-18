import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/ton_investor.tact',
    options: {
        debug: true,
    },
};
