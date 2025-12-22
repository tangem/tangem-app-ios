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

struct NFTCollectionDisclosureGroupViewModel: Identifiable {
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

    var isExpandable: Bool {
        nftCollection.assetsCount > 0
    }

    private let nftCollection: NFTCollection
    private let assetsState: AssetsState
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
        self.assetsState = assetsState
        nftChainIconProvider = dependencies.nftChainIconProvider
        self.onCollectionTap = onCollectionTap

        viewState = assetsState.mapValue { assets in
            let assetsViewModels = assets
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
        return nftCollection.media?.kind == .animation
            || nftCollection.assetsResult.value.contains { NFTAssetMediaExtractor.extractMedia(from: $0)?.kind == .animation }
    }

    func onTap(isExpanded: Bool) {
        onCollectionTap(nftCollection, isExpanded)
    }
}

extension NFTCollectionDisclosureGroupViewModel {
    /// Input state.
    typealias AssetsState = LoadingResult<[NFTAsset], any Error>

    /// Output state.
    typealias ViewState = LoadingResult<NFTAssetsGridViewModel, any Error>
}
