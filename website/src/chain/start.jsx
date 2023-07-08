import { TransactionBlock } from "@mysten/sui.js";

const CONFIG = {
    "TESTNET": {
        PACKAGE: "0x20020", // "0x20020
        CLOCK: "0x6",
        SEED: "0x20021",
        STORE: "0x20022",
        CONFIG: "0x20023",
    }
}

export function createStartTxnBlock(
    choice
) {
    const txb = new TransactionBlock();

    const [coin] = txb.splitCoins(txb.gas, [txb.pure(1 * 10**9)]);

    txb.moveCall({
        target: `${CONFIG.TESTNET.PACKAGE}::gambler::start`,
        typeArguments: [],
        args: [
            txb.object(CONFIG.TESTNET.CLOCK),
            txb.object(CONFIG.TESTNET.SEED),
            txb.object(CONFIG.TESTNET.STORE),
            txb.object(CONFIG.TESTNET.CONFIG),
            txb.pure(choice),
            txb.object(coin)
        ]
    })

    return txb
}

export function createPlayTxnBlock(
    choice,
    card,
    stake
) {
    const txb = new TransactionBlock();

    const [coin] = txb.splitCoins(txb.gas, [txb.pure(stake * 10**9)]);

    txb.moveCall({
        target: `${CONFIG.TESTNET.PACKAGE}::gambler::play`,
        typeArguments: [],
        args: [
            txb.object(CONFIG.TESTNET.CLOCK),
            txb.object(CONFIG.TESTNET.SEED),
            txb.object(CONFIG.TESTNET.STORE),
            txb.object(CONFIG.TESTNET.CONFIG),
            txb.pure(choice),
            txb.object(coin),
            txb.pure(card),
        ]
    })

    return txb
}

export function createOverlordModeTxnBlock(
    card
) {
    const txb = new TransactionBlock();

    txb.moveCall({
        target: `${CONFIG.TESTNET.PACKAGE}::gambler::overlord_mode`,
        typeArguments: [],
        args: [
            txb.object(CONFIG.TESTNET.STORE),
            txb.pure(card),
        ]
    })

    return txb
}