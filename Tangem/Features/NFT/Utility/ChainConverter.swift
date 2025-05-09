//
//  ChainConverter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemNFT
import TangemSdk

enum ChainConverter {
    static func from(nftChain: NFTChain, version: SupportedBlockchains.Version) -> Blockchain {
        switch nftChain {
        case .ethereum(let isTestnet):
            .ethereum(testnet: isTestnet)
        case .polygon(let isTestnet):
            .polygon(testnet: isTestnet)
        case .bsc(let isTestnet):
            .bsc(testnet: isTestnet)
        case .avalanche:
            .avalanche(testnet: false)
        case .fantom:
            .fantom(testnet: false)
        case .cronos:
            .cronos
        case .arbitrum:
            .arbitrum(testnet: false)
        case .gnosis:
            .gnosis
        case .chiliz(let isTestnet):
            .chiliz(testnet: isTestnet)
        case .base(let isTestnet):
            .base(testnet: isTestnet)
        case .optimism:
            .optimism(testnet: false)
        case .moonbeam(let isTestnet):
            .moonbeam(testnet: isTestnet)
        case .moonriver:
            .moonriver(testnet: false)
        case .solana:
            .solana(curve: ed25519Curve(for: version), testnet: false)
        case .aptos:
            .aptos(curve: ed25519Curve(for: version), testnet: false)
        case .ton:
            .ton(curve: ed25519Curve(for: version), testnet: false)
        }
    }

    private static func ed25519Curve(for version: SupportedBlockchains.Version) -> EllipticCurve {
        switch version {
        case .v1:
            return .ed25519
        case .v2:
            return .ed25519_slip0010
        }
    }
}
