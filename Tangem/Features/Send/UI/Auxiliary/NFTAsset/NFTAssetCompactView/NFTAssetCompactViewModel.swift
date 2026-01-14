//
//  NFTAssetCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import TangemLocalization

struct NFTAssetCompactViewModel {
    var assetTitle: String { asset.name }
    var assetSubtitle: String { collection.name }

    let header: SendTokenHeader
    let asset: NFTAsset
    let nftChainIconProvider: NFTChainIconProvider
    let collection: NFTCollection

    init(
        header: SendTokenHeader,
        asset: NFTAsset,
        collection: NFTCollection,
        nftChainIconProvider: NFTChainIconProvider
    ) {
        self.header = header
        self.asset = asset
        self.collection = collection
        self.nftChainIconProvider = nftChainIconProvider
    }
}
