//
//  MoralisSupportedBlockchains.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// Networks supported by Moralis Wallet API (token balances). Used to limit address resolution
/// and token sync to chains we can query via Moralis.
enum MoralisSupportedBlockchains {
    static let all: Set<Blockchain> = [
        Blockchain.ethereum(testnet: false),
        Blockchain.polygon(testnet: false),
        Blockchain.bsc(testnet: false),
        Blockchain.arbitrum(testnet: false),
        Blockchain.optimism(testnet: false),
        Blockchain.avalanche(testnet: false),
        Blockchain.fantom(testnet: false),
        Blockchain.base(testnet: false),
        Blockchain.linea(testnet: false),
        Blockchain.gnosis,
        Blockchain.cronos,
        Blockchain.moonbeam(testnet: false),
        Blockchain.moonriver(testnet: false),
        Blockchain.pulsechain(testnet: false),
        Blockchain.chiliz(testnet: false),
        Blockchain.monad(testnet: false),
        Blockchain.seiEvm(testnet: false),
    ]
}
