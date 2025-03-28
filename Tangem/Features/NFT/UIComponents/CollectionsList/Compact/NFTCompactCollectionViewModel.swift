//
//  NFTCompactCollectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemAssets

final class NFTCompactCollectionViewModel {
    private let nftCollection: NFTCollection
    private let version: SupportedBlockchains.Version

    let assetsViewModels: [NFTCompactAssetViewModel]

    init(nftCollection: NFTCollection, version: SupportedBlockchains.Version) {
        self.nftCollection = nftCollection
        self.version = version
        assetsViewModels = nftCollection.assets.map {
            NFTCompactAssetViewModel(nftAsset: $0)
        }
    }

    var id: String {
        nftCollection.id.collectionIdentifier
    }

    var logoURL: URL? {
        nftCollection.logoURL
    }

    var blockchainImage: ImageType {
        ChainConverter.from(nftChain: nftCollection.id.chain, version: version).iconAssetFilled
    }

    var name: String {
        nftCollection.name
    }

    var numberOfItems: Int {
        nftCollection.assets.count
    }
}
