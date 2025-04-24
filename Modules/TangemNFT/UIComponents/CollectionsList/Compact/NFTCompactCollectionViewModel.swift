//
//  NFTCompactCollectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

final class NFTCompactCollectionViewModel: Identifiable {
    private let nftCollection: NFTCollection
    private let nftChainIconProvider: NFTChainIconProvider

    let assetsGridViewModel: NFTAssetsGridViewModel

    init(nftCollection: NFTCollection, nftChainIconProvider: NFTChainIconProvider) {
        self.nftCollection = nftCollection
        self.nftChainIconProvider = nftChainIconProvider

        let assetsViewModels = nftCollection.assets.map {
            NFTCompactAssetViewModel(nftAsset: $0)
        }
        assetsGridViewModel = NFTAssetsGridViewModel(assetsViewModels: assetsViewModels)
    }

    var id: NFTCollection.ID {
        nftCollection.id
    }

    var logoURL: URL? {
        nftCollection.logoURL
    }

    var blockchainImage: ImageType {
        nftChainIconProvider.provide(by: nftCollection.id.chain)
    }

    var name: String {
        nftCollection.name
    }

    var numberOfItems: Int {
        nftCollection.assets.count
    }
}
