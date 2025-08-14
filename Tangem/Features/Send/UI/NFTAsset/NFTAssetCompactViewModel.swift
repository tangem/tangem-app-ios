//
//  NFTAssetCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT

struct NFTAssetCompactViewModel {
    var id: AnyHashable { asset.id }
    var assetTitle: String { asset.name }
    var assetSubtitle: String { collection.name }

    let asset: NFTAsset
    let nftChainIconProvider: NFTChainIconProvider
    let collection: NFTCollection

    init(
        asset: NFTAsset,
        collection: NFTCollection,
        nftChainIconProvider: NFTChainIconProvider
    ) {
        self.asset = asset
        self.collection = collection
        self.nftChainIconProvider = nftChainIconProvider
    }
}
