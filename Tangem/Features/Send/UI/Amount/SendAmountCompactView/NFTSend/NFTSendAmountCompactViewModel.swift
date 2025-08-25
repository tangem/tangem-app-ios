//
//  NFTSendAmountCompactContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemLocalization

struct NFTSendAmountCompactContentViewModel {
    var id: AnyHashable { asset.id }
    var sectionTitle: String { Localization.nftAsset }
    var assetTitle: String { asset.name }
    var assetSubtitle: String { collection.name }
    let asset: NFTAsset
    let nftChainIconProvider: NFTChainIconProvider

    private let collection: NFTCollection

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
