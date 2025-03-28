//
//  NFTCollectionsCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class NFTEntrypointViewModel: ObservableObject {
    @Published private(set) var state: LoadingValue<CollectionsViewState>
    private var collectionsCount = 0
    private var totalNFTs = 0

    private weak var coordinator: NFTEntrypointRoutable?

    init(initialState: LoadingValue<CollectionsViewState> = .loading, coordinator: NFTEntrypointRoutable) {
        state = initialState
        self.coordinator = coordinator
    }

    var title: String {
        // [REDACTED_TODO_COMMENT]
        "NFT Assets"
    }

    var subtitle: String {
        // [REDACTED_TODO_COMMENT]
        "\(totalNFTs) assets in \(collectionsCount) collections"
    }

    func openCollections() {
        coordinator?.openCollections()
    }
}

extension NFTEntrypointViewModel {
    enum CollectionsViewState {
        case noCollections

        case oneCollection(imageURL: URL)
        case twoCollections(
            firstCollectionImageURL: URL,
            secondCollectionImageURL: URL
        )
        case threeCollections(
            firstCollectionImageURL: URL,
            secondCollectionImageURL: URL,
            thirdCollectionImageURL: URL
        )
        case fourCollections(
            firstCollectionImageURL: URL,
            secondCollectionImageURL: URL,
            thirdCollectionImageURL: URL,
            fourthCollectionImageURL: URL
        )
        case multipleCollections(collectionsURLs: [URL])
    }
}
