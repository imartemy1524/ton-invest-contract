# Ton Investments smart contract

This is a smart contract for investments in TON.

### How does it work:

There is 3 parties in the contract: investor, performer and moderator. Investor invests money, performer performs the work and moderator resolves conflicts.

#### Investment process:
1. Investor creates the smart contract, and "locks" jettons (for example, USDT) in it.
2. Performer "accepts" this contract and starts working.
3. When the subtask is done, investor unlocks the jettons for subtask.
4. After all subtasks are done, investor unlocks the jettons for the whole task.

##### If the work is not done

Performer can cancel the contract and investor would get the jettons back.

#### Conflict resolution:
Any party can request a conflict, and then (and only then) moderator would be able to perform actions as an investor and performer: close the tasks or send them back to the investor.



## Project structure

-   `contracts` - source code of all the smart contracts of the project and their dependencies.
-   `wrappers` - wrapper classes (implementing `Contract` from ton-core) for the contracts, including any [de]serialization primitives and compilation functions.
-   `tests` - tests for the contracts.
-   `scripts` - scripts used by the project, mainly the deployment scripts.

## How to use

### Build

`npx blueprint build` or `yarn blueprint build`

### Test

`npx blueprint test` or `yarn blueprint test`

### Deploy or run another script

`npx blueprint run` or `yarn blueprint run`

### Add a new contract

`npx blueprint create ContractName` or `yarn blueprint create ContractName`
