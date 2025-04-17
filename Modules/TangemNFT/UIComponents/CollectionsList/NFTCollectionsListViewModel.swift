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

public final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""

    private let collections: [NFTCompactCollectionViewModel]
    private var bag = Set<AnyCancellable>()

    public init(collections: [NFTCollection], nftChainIconProvider: NFTChainIconProvider) {
        let collectionsViewModels = collections.map {
            NFTCompactCollectionViewModel(
                nftCollection: $0,
                nftChainIconProvider: nftChainIconProvider
            )
        }

        state = collectionsViewModels.isEmpty ? .noCollections : .collectionsAvailale(collectionsViewModels)
        self.collections = collectionsViewModels
        bindSearchEntry()
    }

    func bindSearchEntry() {
        $searchEntry
            .sink { [weak self] entry in
                guard let self else { return }

                let filteredCollections = filteredCollections(entry: entry)
                state = .collectionsAvailale(filteredCollections)
            }
            .store(in: &bag)
    }

    private func filteredCollections(entry: String) -> [NFTCompactCollectionViewModel] {
        guard entry.isNotEmpty else {
            return collections
        }

        let filteredCollections = collections.filter { collection in
            let collectionNameMatches = collection.name.localizedStandardContains(entry)
            var someAssetsNamesMatch: Bool {
                collection.assetsGridViewModel.assetsViewModels.contains {
                    $0.title.localizedStandardContains(entry)
                }
            }

            return collectionNameMatches || someAssetsNamesMatch
        }

        return filteredCollections
    }
}

extension NFTCollectionsListViewModel {
    enum ViewState {
        case noCollections
        case collectionsAvailale([NFTCompactCollectionViewModel])
    }
}
