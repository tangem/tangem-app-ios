//
//  NFTChainConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
enum NFTChainConverter {
    static func convert(_ nftChain: NFTChain) -> Blockchain {
        fatalError("\(#function) not implemented yet!")
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
}
