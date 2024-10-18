import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/jettons/jettons.tact',
    options: {
        debug: true,
    },
};
