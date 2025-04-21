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
import TangemFoundation
import CombineExt

public final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""

    private let coordinator: NFTCollectionsListRoutable
    private let nftManager: NFTManager
    private let chainIconProvider: NFTChainIconProvider

    private var collectionsViewModels: [NFTCompactCollectionViewModel] = []
    private var bag = Set<AnyCancellable>()

    init(nftManager: NFTManager, chainIconProvider: NFTChainIconProvider, coordinator: NFTCollectionsListRoutable) {
        self.nftManager = nftManager
        self.coordinator = coordinator
        self.chainIconProvider = chainIconProvider
        state = .noCollections

        bind()
    }

    private func bind() {
        nftManager.collectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, collections in
                let collectionsViewModels = collections.map {
                    NFTCompactCollectionViewModel(nftCollection: $0, nftChainIconProvider: viewModel.chainIconProvider)
                }

                self.collectionsViewModels = collectionsViewModels
                return collectionsViewModels.isEmpty ? ViewState.noCollections : .collectionsAvailale(collectionsViewModels)
            }
            .receiveOnMain()
            .assign(to: \.state, on: self, ownership: .weak)
            .store(in: &bag)

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
            return collectionsViewModels
        }

        let filteredCollections = collectionsViewModels.filter { collection in
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
