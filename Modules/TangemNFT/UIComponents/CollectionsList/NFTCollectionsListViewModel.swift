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
    typealias ViewState = LoadingValue<[NFTCompactCollectionViewModel]>

    // MARK: State

    @Published private(set) var state: ViewState
    @Published var searchEntry: String = ""
    @Published private(set) var rowExpanded = false
    @Published private(set) var loadingTroublesViewData: NFTNotificationViewData?

    // MARK: Dependencies

    private let nftManager: NFTManager
    private let chainIconProvider: NFTChainIconProvider
    private let navigationContext: NFTEntrypointNavigationContext

    // MARK: Properties

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
        state = .loading

        bind()
    }

    func onReceiveButtonTap() {
        coordinator?.openReceive(navigationContext: navigationContext)
    }

    func onRetryTap() {
        nftManager.update(cachePolicy: .never)
    }

    private func bind() {
        nftManager
            .statePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, managerState in
                viewModel.map(managerState: managerState)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.updateState(with: result)
                viewModel.loadingTroublesViewData = result.notificationViewData
            }
            .store(in: &bag)

        $searchEntry
            .withWeakCaptureOf(self)
            .dropFirst()
            .sink { viewModel, entry in
                let filteredCollections = viewModel.filteredCollections(entry: entry)
                viewModel.state = .loaded(filteredCollections)
            }
            .store(in: &bag)
    }

    private func map(managerState: NFTManagerState) -> ManagerStateMappingResult {
        switch managerState {
        case .failedToLoad(let error):
            return .init(
                viewState: .failedToLoad(error: error),
                notificationViewData: nil
            )

        case .loading:
            return .init(
                viewState: .loading,
                notificationViewData: nil
            )

        case .loaded(let collectionsResult):
            let collectionsViewModels = buildCollections(from: collectionsResult.value)
            self.collectionsViewModels = collectionsViewModels

            let loadingTroublesViewData = collectionsResult.hasErrors ?
                makeNotificationViewData()
                : nil

            return .init(
                viewState: .loaded(collectionsViewModels),
                notificationViewData: loadingTroublesViewData
            )
        }
    }

    private func updateState(with result: ManagerStateMappingResult) {
        let hadErrorsWhileLoading = result.notificationViewData != nil
        let currentCollections = state.value ?? []

        switch result.viewState {
        case .loaded(let collections) where hadErrorsWhileLoading && collections.isEmpty && state.isLoading:
            // We don't need error here, NSError used to silence the compiler
            state = .failedToLoad(error: NSError(domain: "", code: 0))

        case .loaded(let collections) where hadErrorsWhileLoading && collections.isEmpty:
            break  // Keep previous state (non-loading)

        case .loaded(let collections):
            state = .loaded(collections)

        case .loading where currentCollections.isEmpty:
            state = .loading

        case .loading:
            break // Keep previous state

        case .failedToLoad(let error):
            state = .failedToLoad(error: error)
        }
    }

    private func buildCollections(from collections: [NFTCollection]) -> [NFTCompactCollectionViewModel] {
        collections
            .sorted { $0.name.caseInsensitiveSmaller(than: $1.name) }
            .map { collection in
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

        if shouldLoadAssets(for: collection, isExpanded: isExpanded) {
            nftManager.updateAssets(inCollectionWithIdentifier: collection.id)
        }
    }

    private func shouldLoadAssets(for collection: NFTCollection, isExpanded: Bool) -> Bool {
        let noAssetsLoaded = collection.assets.isEmpty
        let hasAssets = collection.assetsCount != 0

        return noAssetsLoaded && hasAssets && isExpanded
    }

    private func makeNotificationViewData() -> NFTNotificationViewData {
        NFTNotificationViewData(
            title: Localization.nftCollectionsWarningTitle,
            subtitle: Localization.nftCollectionsWarningSubtitle,
            icon: Assets.warningIcon
        )
    }
}

// MARK: - Helpers

private extension NFTCollectionsListViewModel {
    struct ManagerStateMappingResult {
        let viewState: ViewState
        let notificationViewData: NFTNotificationViewData?
    }
}
