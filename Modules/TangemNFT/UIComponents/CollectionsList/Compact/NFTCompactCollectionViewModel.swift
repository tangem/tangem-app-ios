//
//  NFTCompactCollectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

final class NFTCompactCollectionViewModel: Identifiable, ObservableObject {
    @Published private(set) var isExpanded: Bool = false

    private let nftCollection: NFTCollection
    private let nftChainIconProvider: NFTChainIconProvider
    private let onTapAction: () -> Void

    let assetsGridViewModel: NFTAssetsGridViewModel

    init(
        nftCollection: NFTCollection,
        nftChainIconProvider: NFTChainIconProvider,
        openAssetDetailsAction: @escaping (NFTAsset) -> Void,
        onTapAction: @escaping () -> Void
    ) {
        self.nftCollection = nftCollection
        self.nftChainIconProvider = nftChainIconProvider
        self.onTapAction = onTapAction

        let assetsViewModels = nftCollection.assets.map {
            NFTCompactAssetViewModel(nftAsset: $0, openAssetDetailsAction: openAssetDetailsAction)
        }
        assetsGridViewModel = NFTAssetsGridViewModel(assetsViewModels: assetsViewModels)
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
        nftCollection.assetsCount
    }

    func onTap() {
        isExpanded.toggle()
        onTapAction()
    }
}
