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

    public init(nftChainNameProvider: NFTChainNameProviding, priceFormatter: NFTPriceFormatting) {
        self.nftChainNameProvider = nftChainNameProvider
        self.priceFormatter = priceFormatter
    }
}
