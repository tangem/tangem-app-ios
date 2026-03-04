//
//  MoralisSupportedBlockchains.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Networks supported by Moralis Wallet API (token balances). Used to limit address resolution
/// and token sync to chains we can query via Moralis.
enum MoralisSupportedBlockchains {
    static let networkIds: Set<String> = [
        Blockchain.ethereum(testnet: false).networkId,
        Blockchain.polygon(testnet: false).networkId,
        Blockchain.bsc(testnet: false).networkId,
        Blockchain.arbitrum(testnet: false).networkId,
        Blockchain.optimism(testnet: false).networkId,
        Blockchain.avalanche(testnet: false).networkId,
        Blockchain.fantom(testnet: false).networkId,
        Blockchain.base(testnet: false).networkId,
        Blockchain.linea(testnet: false).networkId,
        Blockchain.gnosis.networkId,
        Blockchain.cronos.networkId,
        Blockchain.moonbeam(testnet: false).networkId,
        Blockchain.moonriver(testnet: false).networkId,
        Blockchain.pulsechain(testnet: false).networkId,
        Blockchain.chiliz(testnet: false).networkId,
        Blockchain.monad(testnet: false).networkId,
    ]
}
