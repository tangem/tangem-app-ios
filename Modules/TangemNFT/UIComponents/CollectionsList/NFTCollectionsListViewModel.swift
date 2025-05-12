//
//  NFTCollectionsListViewModel.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemAssets

public final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""
    @Published private(set) var rowExpanded = false

    // MARK: Dependencies

    private let nftManager: NFTManager
    private let chainIconProvider: NFTChainIconProvider
    private let navigationContext: NFTEntrypointNavigationContext

    private var collectionsViewModels: [NFTCompactCollectionViewModel] = []
    private var bag = Set<AnyCancellable>()

    private weak var coordinator: NFTCollectionsListRoutable?

    public init(
        nftManager: NFTManager,
        chainIconProvider: NFTChainIconProvider,
        navigationContext: NFTEntrypointNavigationContext,
        coordinator: NFTCollectionsListRoutable?
    ) {
        self.nftManager = nftManager
        self.coordinator = coordinator
        self.chainIconProvider = chainIconProvider
        self.navigationContext = navigationContext
        state = .noCollections

        bind()
    }

    func onReceiveButtonTap() {
        coordinator?.openReceive(navigationContext: navigationContext)
    }

    private func bind() {
        nftManager
            .collectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, collections in
                let collectionsViewModels = viewModel.buildCollections(from: collections)
                viewModel.collectionsViewModels = collectionsViewModels
                return collectionsViewModels.isEmpty ? .noCollections : .collectionsAvailable(collectionsViewModels)
            }
            .receiveOnMain()
            .assign(to: \.state, on: self, ownership: .weak)
            .store(in: &bag)

        $searchEntry
            .withWeakCaptureOf(self)
            .sink { viewModel, entry in
                let filteredCollections = viewModel.filteredCollections(entry: entry)
                viewModel.state = .collectionsAvailable(filteredCollections)
            }
            .store(in: &bag)
    }

    private func buildCollections(from collections: [NFTCollection]) -> [NFTCompactCollectionViewModel] {
        return collections.map { collection in
            NFTCompactCollectionViewModel(
                nftCollection: collection,
                assetsState: collection.assets.isEmpty ? .loading : .loaded(()),
                nftChainIconProvider: chainIconProvider,
                openAssetDetailsAction: { [weak self] asset in
                    self?.openAssetDetails(asset)
                },
                onCollectionTap: { [weak self] collection, isExpanded in
                    self?.onCollectionTap(collection: collection, isExpanded: isExpanded)
                }
            )
        }
    }

    private func filteredCollections(entry: String) -> [NFTCompactCollectionViewModel] {
        guard entry.isNotEmpty else {
            return collectionsViewModels
        }

        let filteredCollections = collectionsViewModels.filter { collection in
            let collectionNameMatches = collection.name.localizedStandardContains(entry)
            var someAssetsNamesMatch: Bool {
                let assetsViewModels = collection.viewState.value?.assetsViewModels ?? []

                return assetsViewModels.contains {
                    $0.state.asset?.name.localizedStandardContains(entry) ?? false
                }
            }

            return collectionNameMatches || someAssetsNamesMatch
        }

        return filteredCollections
    }

    private func openAssetDetails(_ asset: NFTAsset) {
        coordinator?.openAssetDetails(asset: asset)
    }

    private func onCollectionTap(collection: NFTCollection, isExpanded: Bool) {
        rowExpanded.toggle()

        if isExpanded {
            nftManager.updateAssets(inCollectionWithIdentifier: collection.id)
        }
    }
}

extension NFTCollectionsListViewModel {
    enum ViewState {
        case noCollections
        case collectionsAvailable([NFTCompactCollectionViewModel])
    }
}
