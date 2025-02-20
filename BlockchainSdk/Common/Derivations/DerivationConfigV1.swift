//
//  DerivationConfigV1.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Documentation:
/// Types:
/// - `Stellar`, `Solana`. According to `SEP0005`
/// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
/// - `Cardano`. According to  `CIP1852`
/// https://cips.cardano.org/cips/cip1852/
/// - `All else`. According to `BIP44`
/// https://github.com/satoshilabs/slips/blob/master/slip-0044.md
struct DerivationConfigV1: DerivationConfig {
    func derivationPath(for blockchain: Blockchain) -> String {
        switch blockchain {
        case .bitcoin:
            return "m/44'/0'/0'/0/0"
        case .litecoin:
            return "m/44'/2'/0'/0/0"
        case .stellar:
            return "m/44'/148'/0'"
        case .solana:
            return "m/44'/501'/0'"
        case .cardano:
            return "m/1852'/1815'/0'/0/0"
        case .bitcoinCash:
            return "m/44'/145'/0'/0/0"
        case .ethereum,
             .ethereumPoW,
             .disChain,
             .octa,
             .decimal,
             .shibarium,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .polygonZkEVM,
             .mantle,
             .flare,
             .taraxa,
             .base,
             .cyber,
             .blast,
             .canxium,
             .chiliz,
             .xodex,
             .apeChain,
             .vanar:
            return "m/44'/60'/0'/0/0"
        case .ethereumClassic:
            return "m/44'/61'/0'/0/0"
        case .rsk:
            return "m/44'/137'/0'/0/0"
        case .binance:
            return "m/44'/714'/0'/0/0"
        case .xrp:
            return "m/44'/144'/0'/0/0"
        case .ducatus:
            return "m/44'/0'/0'/0/0"
        case .tezos:
            return "m/44'/1729'/0'/0/0"
        case .dogecoin:
            return "m/44'/3'/0'/0/0"
        case .bsc:
            return "m/44'/9006'/0'/0/0"
        case .polygon:
            return "m/44'/966'/0'/0/0"
        case .avalanche:
            return "m/44'/9000'/0'/0/0"
        case .fantom:
            return "m/44'/1007'/0'/0/0"
        case .polkadot:
            return "m/44'/354'/0'/0/0"
        case .kusama:
            return "m/44'/434'/0'/0/0"
        case .azero:
            return "m/44'/643'/0'/0'/0'"
        case .joystream:
            return "m/44'/1014'/0'/0'/0'"
        case .tron:
            return "m/44'/195'/0'/0/0"
        case .arbitrum:
            return "m/44'/9001'/0'/0/0"
        case .dash:
            return "m/44'/5'/0'/0/0"
        case .gnosis:
            return "m/44'/700'/0'/0/0"
        case .optimism:
            return "m/44'/614'/0'/0/0"
        case .ton:
            return "m/44'/607'/0'/0/0"
        case .kava:
            return "m/44'/459'/0'/0/0"
        case .kaspa:
            return "m/44'/111111'/0'/0/0"
        case .ravencoin:
            return "m/44'/175'/0'/0/0"
        case .cosmos, .sei:
            return "m/44'/118'/0'/0/0"
        case .terraV1, .terraV2:
            return "m/44'/330'/0'/0/0"
        case .cronos:
            return "m/44'/10000025'/0'/0/0"
        case .telos:
            return "m/44'/977'/0'/0/0"
        case .chia:
            return ""
        case .near:
            return "m/44'/397'/0'"
        case .veChain:
            return "m/44'/818'/0'/0/0"
        case .xdc:
            return "m/44'/550'/0'/0/0"
        case .algorand:
            return "m/44'/283'/0'/0'/0'"
        case .aptos:
            return "m/44'/637'/0'/0'/0'"
        case .hedera:
            return "m/44'/3030'/0'/0'/0'"
        case .moonbeam:
            return "m/44'/1284'/0'/0/0"
        case .moonriver:
            return "m/44'/1285'/0'/0/0"
        case .radiant:
            return "m/44'/512'/0'/0/0"
        case .bittensor:
            return "m/44'/1005'/0'/0'/0'"
        case .koinos:
            return "m/44'/659'/0'/0/0"
        case .internetComputer:
            return "m/44'/223'/0'/0/0"
        case .sui:
            return "m/44'/784'/0'/0'/0'"
        case .filecoin:
            return "m/44'/461'/0'/0/0"
        case .energyWebEVM:
            return "m/44'/246'/0'/0/0"
        case .energyWebX:
            return "m/44'/246'/0'/0'/0'"
        case .core:
            return "m/44'/1116'/0'/0/0"
        case .casper:
            return "m/44'/506'/0'/0/0"
        case .clore:
            return "m/44'/1313'/0'/0/0"
        case .fact0rn:
            return "m/84'/42069'/0'/0/0"
        case .odysseyChain:
            return "m/44'/695'/0'/0/0"
        case .bitrock:
            return "m/44'/7171666'/0'/0/0"
        case .sonic:
            return "m/44'/10007'/0'/0/0"
        case .alephium:
            return "m/44'/1234'/0'/0/0"
        }
    }
}
