//
//  NFTCollectionsListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemAssets

final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState

    init(collections: [NFTCollection], nftChainIconProvider: NFTChainIconProvider) {
        let collectionsViewModels = collections.map {
            NFTCompactCollectionViewModel(
                nftCollection: $0,
                nftChainIconProvider: nftChainIconProvider
            )
        }

        state = collectionsViewModels.isEmpty ? .empty : .nonEmpty(collectionsViewModels)
    }
}

extension NFTCollectionsListViewModel {
    enum ViewState {
        case empty
        case nonEmpty([NFTCompactCollectionViewModel])
    }
}
