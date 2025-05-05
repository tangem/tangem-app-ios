//
//  NFTChainConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNFT
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
enum NFTChainConverter {
    static func convert(_ nftChain: NFTChain, version: SupportedBlockchains.Version) -> Blockchain {
        switch nftChain {
        case .ethereum(let isTestnet):
            return .ethereum(testnet: isTestnet)
        case .polygon(let isTestnet):
            return .polygon(testnet: isTestnet)
        case .bsc(let isTestnet):
            return .bsc(testnet: isTestnet)
        case .avalanche:
            return .avalanche(testnet: false)
        case .fantom:
            return .fantom(testnet: false)
        case .cronos:
            return .cronos
        case .arbitrum:
            return .arbitrum(testnet: false)
        case .gnosis:
            return .gnosis
        case .chiliz(let isTestnet):
            return .chiliz(testnet: isTestnet)
        case .base(let isTestnet):
            return .base(testnet: isTestnet)
        case .optimism:
            return .optimism(testnet: false)
        case .moonbeam(let isTestnet):
            return .moonbeam(testnet: isTestnet)
        case .moonriver:
            return .moonriver(testnet: false)
        case .solana:
            return .solana(curve: ed25519Curve(for: version), testnet: false)
        }
    }

    static func convert(_ blockchain: Blockchain) -> NFTChain? {
        switch blockchain {
        case .ethereum(let testnet):
            return .ethereum(isTestnet: testnet)
        case .bsc(let testnet):
            return .bsc(isTestnet: testnet)
        case .polygon(let testnet):
            return .polygon(isTestnet: testnet)
        case .avalanche(let testnet) where !testnet:
            return .avalanche
        case .solana(_, testnet: let testnet) where !testnet:
            return .solana
        case .fantom(let testnet) where !testnet:
            return .fantom
        case .arbitrum(let testnet) where !testnet:
            return .arbitrum
        case .gnosis:
            return .gnosis(isTestnet: false)
        case .optimism(let testnet) where !testnet:
            return .optimism
        case .cronos:
            return .cronos
        case .moonbeam(let testnet):
            return .moonbeam(isTestnet: testnet)
        case .moonriver(let testnet) where !testnet:
            return .moonriver
        case .base(let testnet):
            return .base(isTestnet: testnet)
        case .chiliz(let testnet):
            return .chiliz(isTestnet: testnet)
        case .avalanche,
             .solana,
             .fantom,
             .arbitrum,
             .optimism,
             .pulsechain,
             .moonriver,
             .bitcoin,
             .litecoin,
             .stellar,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .bitcoinCash,
             .binance,
             .cardano,
             .xrp,
             .ducatus,
             .tezos,
             .dogecoin,
             .polkadot,
             .kusama,
             .azero,
             .tron,
             .dash,
             .ton,
             .kava,
             .kaspa,
             .ravencoin,
             .cosmos,
             .terraV1,
             .terraV2,
             .telos,
             .octa,
             .chia,
             .near,
             .decimal,
             .veChain,
             .xdc,
             .algorand,
             .shibarium,
             .aptos,
             .hedera,
             .areon,
             .playa3ullGames,
             .aurora,
             .manta,
             .zkSync,
             .mantle,
             .flare,
             .taraxa,
             .radiant,
             .polygonZkEVM,
             .joystream,
             .bittensor,
             .koinos,
             .internetComputer,
             .cyber,
             .blast,
             .sui,
             .filecoin,
             .sei,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper,
             .xodex,
             .clore,
             .fact0rn,
             .odysseyChain,
             .bitrock,
             .apeChain,
             .sonic,
             .alephium,
             .vanar,
             .zkLinkNova,
             .pepecoin:
            return nil
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
