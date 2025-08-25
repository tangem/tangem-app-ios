//
//  NFTAssetDetailsDependencies.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTAssetDetailsDependencies {
    let nftChainNameProvider: NFTChainNameProviding
    let priceFormatter: NFTPriceFormatting
    let analytics: NFTAnalytics.Details

    public init(nftChainNameProvider: NFTChainNameProviding, priceFormatter: NFTPriceFormatting, analytics: NFTAnalytics.Details) {
        self.nftChainNameProvider = nftChainNameProvider
        self.priceFormatter = priceFormatter
        self.analytics = analytics
    }
}
