//
//  NFTCompactCollectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemFoundation

struct NFTCompactCollectionViewModel: Identifiable {
    let viewState: ViewState

    var media: NFTMedia? {
        nftCollection.media
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

    var id: AnyHashable {
        nftCollection.id
    }

    private let nftCollection: NFTCollection
    private let nftChainIconProvider: NFTChainIconProvider
    private let onCollectionTap: (_ collection: NFTCollection, _ isExpanded: Bool) -> Void

    init(
        nftCollection: NFTCollection,
        assetsState: AssetsState,
        nftChainIconProvider: NFTChainIconProvider,
        openAssetDetailsAction: @escaping (_ asset: NFTAsset) -> Void,
        onCollectionTap: @escaping (_ collection: NFTCollection, _ isExpanded: Bool) -> Void
    ) {
        self.nftCollection = nftCollection
        self.nftChainIconProvider = nftChainIconProvider
        self.onCollectionTap = onCollectionTap

        viewState = assetsState.mapValue { _ in
            let assetsViewModels = nftCollection
                .assets
                .map { NFTCompactAssetViewModel(nftAsset: $0, openAssetDetailsAction: openAssetDetailsAction) }

            return NFTAssetsGridViewModel(assetsViewModels: assetsViewModels)
        }
    }

    func onTap(isExpanded: Bool) {
        onCollectionTap(nftCollection, isExpanded)
    }
}

extension NFTCompactCollectionViewModel {
    /// Input state.
    typealias AssetsState = LoadingValue<Void>

    /// Output state.
    typealias ViewState = LoadingValue<NFTAssetsGridViewModel>
}
