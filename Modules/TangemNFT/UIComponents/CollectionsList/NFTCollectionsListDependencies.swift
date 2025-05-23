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
    let priceFormatter: NFTPriceFormatting

    public init(nftChainIconProvider: NFTChainIconProvider, priceFormatter: NFTPriceFormatting) {
        self.nftChainIconProvider = nftChainIconProvider
        self.priceFormatter = priceFormatter
    }
}
