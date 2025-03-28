//
//  NFTCollectionsListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT

final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var collectionsViewModels: [NFTCompactCollectionViewModel] = []

    init(collections: [NFTCollection]) {
        collectionsViewModels = collections.map { NFTCompactCollectionViewModel(nftCollection: $0, version: .v2) }
    }
}
