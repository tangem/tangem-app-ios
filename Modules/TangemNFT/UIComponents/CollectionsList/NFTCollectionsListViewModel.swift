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
import TangemLocalization
import TangemFoundation

public final class NFTCollectionsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""
    @Published private(set) var rowExpanded = false
    @Published private(set) var loadingTroublesViewData: NFTNotificationViewData?

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
            .map { viewModel, collectionsResponse in
                let collectionsViewModels = viewModel.buildCollections(from: collectionsResponse.value)
                viewModel.collectionsViewModels = collectionsViewModels
                let state = collectionsViewModels.isEmpty ? ViewState.noCollections : .collectionsAvailable(collectionsViewModels)

                let loadingTroublesViewData = collectionsResponse.hasErrors ?
                    viewModel.makeNotificationViewData()
                    : nil

                return (state: state, loadingTroublesViewData: loadingTroublesViewData)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.state = result.state
                viewModel.loadingTroublesViewData = result.loadingTroublesViewData
            }
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
        collections.map { collection in
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

    private func makeNotificationViewData() -> NFTNotificationViewData {
        NFTNotificationViewData(
            title: Localization.nftCollectionsWarningTitle,
            subtitle: Localization.nftCollectionsWarningSubtitle,
            icon: Assets.warningIcon
        )
    }
}

extension NFTCollectionsListViewModel {
    enum ViewState {
        case noCollections
        case collectionsAvailable([NFTCompactCollectionViewModel])
    }
}
