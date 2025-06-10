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
    private let isLongHashesSupported: Bool
    private var testableNFTChainsIds: [String] { FeatureStorage.instance.testableNFTChainsIds }

    init(userWalletConfig: UserWalletConfig) {
        isLongHashesSupported = userWalletConfig.hasFeature(.longHashes)
    }

    func isNFTAvailable(for tokenItem: TokenItem) -> Bool {
        guard tokenItem.isBlockchain else {
            return false
        }

        let appUtils = AppUtils()

        if appUtils.hasLongHashesForContractInteractions(tokenItem), !isLongHashesSupported {
            return false
        }

        if !appUtils.canPerformContractInteractions(with: tokenItem) {
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
        return []
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
