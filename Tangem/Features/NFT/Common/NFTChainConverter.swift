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
        case .fantom(let isTestnet):
            return .fantom(testnet: isTestnet)
        case .cronos:
            return .cronos
        case .arbitrum(let isTestnet):
            return .arbitrum(testnet: isTestnet)
        case .chiliz(let isTestnet):
            return .chiliz(testnet: isTestnet)
        case .base(let isTestnet):
            return .base(testnet: isTestnet)
        case .optimism(let isTestnet):
            return .optimism(testnet: isTestnet)
        case .moonbeam(let isTestnet):
            return .moonbeam(testnet: isTestnet)
        case .moonriver(let isTestnet):
            return .moonriver(testnet: isTestnet)
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
        case .fantom(let testnet):
            return .fantom(isTestnet: testnet)
        case .arbitrum(let testnet):
            return .arbitrum(isTestnet: testnet)
        case .optimism(let testnet):
            return .optimism(isTestnet: testnet)
        case .cronos:
            return .cronos
        case .moonbeam(let testnet):
            return .moonbeam(isTestnet: testnet)
        case .moonriver(let testnet):
            return .moonriver(isTestnet: testnet)
        case .base(let testnet):
            return .base(isTestnet: testnet)
        case .chiliz(let testnet):
            return .chiliz(isTestnet: testnet)
        case .avalanche,
             .solana,
             .pulsechain,
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
             .gnosis,
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
             .pepecoin,
             .hyperliquidEVM,
             .quai,
             .scroll,
             .linea,
             .monad,
             .arbitrumNova,
             .plasma:
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
