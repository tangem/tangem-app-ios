//
//  SupportedBlockchains.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SupportedBlockchains {
    func emvBlockchains() -> Set<Blockchain> {
        mainnetBlockchains(for: .v1)
            .union(testnetBlockchains())
            .filter { $0.isEvm }
    }

    func blockchains(for version: Version) -> Set<Blockchain> {
        if AppEnvironment.current.isTestnet {
            return testnetBlockchains()
        }

        let mainnetBlockchains = mainnetBlockchains(for: version)

        // For production return only mainnetBlockchains
        if AppEnvironment.current.isProduction {
            return mainnetBlockchains
        }

        let betaTestingBlockchains = FeatureStorage().supportedBlockchainsIds.compactMap { Blockchain(from: $0) }

        return mainnetBlockchains.union(Set(betaTestingBlockchains))
    }

    func mainnetBlockchains(for version: Version) -> Set<Blockchain> {
        [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .ethereumPoW(testnet: false),
            .ethereumFair,
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: version == .v2 ? .ed25519 : .secp256k1),
            .stellar(testnet: false),
            .cardano,
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
            .polkadot(testnet: false),
            .kusama,
            .azero(testnet: false),
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .gnosis,
            .dash(testnet: false),
            .optimism(testnet: false),
            .ton(testnet: false),
            .kava(testnet: false),
            .kaspa,
            .ravencoin(testnet: false),
            .cosmos(testnet: false),
            .terraV1,
            .terraV2,
            .cronos,
        ]
    }

    func testnetBlockchains() -> Set<Blockchain> {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .ethereumClassic(testnet: true),
            .ethereumPoW(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(testnet: true),
            .fantom(testnet: true),
            .polkadot(testnet: true),
            .azero(testnet: true),
            .tron(testnet: true),
            .arbitrum(testnet: true),
            .optimism(testnet: true),
            .ton(testnet: true),
            .kava(testnet: true),
            .ravencoin(testnet: true),
            .cosmos(testnet: true),
        ]
    }
}

extension SupportedBlockchains {
    enum Version {
        /// All legacy cards
        case v1

        /// Wallet 2.0
        case v2
    }
}
