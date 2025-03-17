//
//  NFTCollectionsCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class NFTCollectionsCompactViewModel: ObservableObject {
    @Published private(set) var state: ViewState

    init(initialState: ViewState = .loading) {
        state = initialState
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }

        return false
    }

    var title: String {
        "NFT Collections"
    }

    var subtitle: String {
        "125 NFTs in 4 collections"
    }
}

extension NFTCollectionsCompactViewModel {
    enum ViewState {
        case loading
        case failed
        case success(CollectionsViewState)
    }
}

extension NFTCollectionsCompactViewModel.ViewState {
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
