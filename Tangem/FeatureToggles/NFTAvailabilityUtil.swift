//
//  NFTAvailabilityUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNFT
import TangemFoundation
import BlockchainSdk

/// NFT feature availability for a particular blockchain.
final class NFTAvailabilityUtil {
    private var isTestnet: Bool { AppEnvironment.current.isTestnet }
    private var testableNFTChainsIds: [String] { FeatureStorage.instance.testableNFTChainsIds }
    private let hardwareLimitationsUtil: HardwareLimitationsUtil

    init(userWalletConfig: UserWalletConfig) {
        hardwareLimitationsUtil = HardwareLimitationsUtil(config: userWalletConfig)
    }

    func isNFTAvailable(for tokenItem: TokenItem) -> Bool {
        guard tokenItem.isBlockchain else {
            return false
        }

        guard hardwareLimitationsUtil.canPerformContractInteractions(with: tokenItem) else {
            return false
        }

        guard let nftChain = NFTChainConverter.convert(tokenItem.blockchain) else {
            return false
        }

        let isProduction = productionNFTChains().contains(nftChain)
        let isTestable = testableNFTChains().contains(nftChain)

        return isProduction || isTestable
    }
}

extension NFTAvailabilityUtil {
    private func productionNFTChains() -> Set<NFTChain> {
        return [
            .ethereum(isTestnet: isTestnet),
            .polygon(isTestnet: isTestnet),
            .bsc(isTestnet: isTestnet),
            .avalanche,
            .fantom(isTestnet: isTestnet),
            .cronos,
            .arbitrum(isTestnet: isTestnet),
            .chiliz(isTestnet: isTestnet),
            .base(isTestnet: isTestnet),
            .optimism(isTestnet: isTestnet),
            .moonbeam(isTestnet: isTestnet),
            .moonriver(isTestnet: isTestnet),
            .solana,
        ]
    }

    func testableNFTChains() -> Set<NFTChain> {
        let allNFTChainsKeyedById = NFTChain
            .allCases(isTestnet: isTestnet)
            .keyedFirst(by: \.id)

        return testableNFTChainsIds
            .compactMap { allNFTChainsKeyedById[$0] }
            .toSet()
    }
}
