//
//  NFTCollectionsListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets

final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var collectionsViewModels: [NFTCompactCollectionViewModel] = []

    init(collections: [NFTCollection], nftChainIconProvider: NFTChainIconProvider) {
        collectionsViewModels = collections.map {
            NFTCompactCollectionViewModel(
                nftCollection: $0,
                nftChainIconProvider: nftChainIconProvider
            )
        }
    }
}
