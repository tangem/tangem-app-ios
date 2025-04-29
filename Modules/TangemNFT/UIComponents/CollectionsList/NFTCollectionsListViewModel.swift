//
//  NFTCollectionsListViewModel.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemAssets
import CombineExt

public final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""
    @Published private(set) var rowExpanded = false

    // MARK: Dependencies

    private weak var coordinator: NFTCollectionsListRoutable?
    private let nftManager: NFTManager
    private let chainIconProvider: NFTChainIconProvider

    private var collectionsViewModels: [NFTCompactCollectionViewModel] = []
    private var bag = Set<AnyCancellable>()

    public init(
        nftManager: NFTManager,
        chainIconProvider: NFTChainIconProvider,
        coordinator: NFTCollectionsListRoutable?
    ) {
        self.nftManager = nftManager
        self.coordinator = coordinator
        self.chainIconProvider = chainIconProvider
        state = .noCollections

        bind()
    }

    func onReceiveButtonTap() {
        // [REDACTED_TODO_COMMENT]
    }

    private func bind() {
        nftManager.collectionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, collections in
                let collectionsViewModels = collections.map {
                    NFTCompactCollectionViewModel(
                        nftCollection: $0,
                        nftChainIconProvider: viewModel.chainIconProvider,
                        openAssetDetailsAction: { [weak self] in
                            self?.openAssetDetails($0)
                        },
                        onTapAction: { [weak self] in
                            self?.rowExpanded.toggle()
                        }
                    )
                }

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

    private func openAssetDetails(_ asset: NFTAsset) {
        coordinator?.openAssetDetails(asset: asset)
    }
}

extension NFTCollectionsListViewModel {
    enum ViewState {
        case noCollections
        case collectionsAvailable([NFTCompactCollectionViewModel])
    }
}
