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
        dependencies: NFTCollectionsListDependencies,
        openAssetDetailsAction: @escaping (_ asset: NFTAsset) -> Void,
        onCollectionTap: @escaping (_ collection: NFTCollection, _ isExpanded: Bool) -> Void
    ) {
        self.nftCollection = nftCollection
        nftChainIconProvider = dependencies.nftChainIconProvider
        self.onCollectionTap = onCollectionTap

        viewState = assetsState.mapValue { _ in
            let assetsViewModels = nftCollection
                .assets
                .sorted { $0.name.caseInsensitiveSmaller(than: $1.name) }
                .map { asset in
                    return NFTCompactAssetViewModel(
                        state: .loaded(.init(asset: asset, priceFormatter: dependencies.priceFormatter)),
                        openAssetDetailsAction: openAssetDetailsAction
                    )
                }

            return NFTAssetsGridViewModel(assetsViewModels: assetsViewModels)
        }
    }

    var containsGIFs: Bool {
        nftCollection.media?.kind == .animation ||
            nftCollection.assets.contains { $0.media?.kind == .animation }
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
