//
//  NFTCollectionsListDependencies.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTCollectionsListDependencies {
    let nftChainIconProvider: NFTChainIconProvider
    let nftChainNameProviding: NFTChainNameProviding
    let priceFormatter: NFTPriceFormatting
    let analytics: NFTAnalytics.Collections

    public init(
        nftChainIconProvider: NFTChainIconProvider,
        nftChainNameProviding: NFTChainNameProviding,
        priceFormatter: NFTPriceFormatting,
        analytics: NFTAnalytics.Collections
    ) {
        self.nftChainIconProvider = nftChainIconProvider
        self.priceFormatter = priceFormatter
        self.analytics = analytics
        self.nftChainNameProviding = nftChainNameProviding
    }
}
