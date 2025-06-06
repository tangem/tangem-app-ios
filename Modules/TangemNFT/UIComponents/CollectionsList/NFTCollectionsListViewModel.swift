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
    @Published private(set) var tappedRowID: AnyHashable? = nil
    @Published private(set) var loadingTroublesViewData: NFTNotificationViewData?

    private var collectionsViewModels: [NFTCompactCollectionViewModel] = []
    private var bag = Set<AnyCancellable>()

    // MARK: Dependencies

    private let nftManager: NFTManager
    private let navigationContext: NFTNavigationContext
    private let dependencies: NFTCollectionsListDependencies
    private let assetSendPublisher: AnyPublisher<NFTAsset, Never>

    private weak var coordinator: NFTCollectionsListRoutable?
    private var pullToRefreshCompletion: (() -> Void)?
    private var didAppear = false

    public init(
        nftManager: NFTManager,
        navigationContext: NFTNavigationContext,
        dependencies: NFTCollectionsListDependencies,
        assetSendPublisher: AnyPublisher<NFTAsset, Never>,
        coordinator: NFTCollectionsListRoutable?
    ) {
        self.nftManager = nftManager
        self.coordinator = coordinator
        self.dependencies = dependencies
        self.assetSendPublisher = assetSendPublisher
        self.navigationContext = navigationContext
        state = .loading
    }

    func onViewAppear() {
        if didAppear {
            return
        }

        didAppear = true
        bind()
        updateInternal()
    }

    func onReceiveButtonTap() {
        coordinator?.openReceive(navigationContext: navigationContext)
        dependencies.analytics.logReceiveOpen()
    }

    func update(completion: (() -> Void)? = nil) {
        pullToRefreshCompletion = completion
        guard !state.isLoading else { return }
        updateInternal()
    }

    var isSearchable: Bool {
        switch state {
        case .failedToLoad:
            false
        case .loaded(let collections) where isStateEmpty(collections: collections):
            false
        case .loaded, .loading:
            true
        }
    }

    func isStateEmpty(collections: [NFTCompactCollectionViewModel]) -> Bool {
        collections.isEmpty && searchEntry.isEmpty
    }

    private func updateInternal() {
        nftManager.update(cachePolicy: .never)
    }

    private func bind() {
        nftManager
            .statePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, managerState in
                let result = viewModel.map(managerState: managerState)
                viewModel.collectionsViewModels = result.viewState.value ?? []

                return ManagerStateMappingResult(
                    viewState: viewModel.processViewState(result.viewState),
                    notificationViewData: result.notificationViewData
                )
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                if let completion = viewModel.pullToRefreshCompletion, !result.viewState.isLoading {
                    completion()
                    viewModel.pullToRefreshCompletion = nil
                }

                viewModel.updateState(with: result)
                viewModel.loadingTroublesViewData = result.notificationViewData
            }
            .store(in: &bag)

        $searchEntry
            .withWeakCaptureOf(self)
            .dropFirst()
            .sink { viewModel, entry in
                viewModel.filterAndAssignCollections(for: entry)
            }
            .store(in: &bag)

        assetSendPublisher
            .delay(for: Constants.assetSendUpdateDelay, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.update()
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
                notificationViewData: loadingTroublesViewData
            )

        case .loaded(let collectionsResult):
            let loadingTroublesViewData = collectionsResult.hasErrors ?
                makeNotificationViewData()
                : nil

            return .init(
                viewState: .loaded(buildCollections(from: collectionsResult.value)),
                notificationViewData: loadingTroublesViewData
            )
        }
    }

    private func processViewState(_ viewState: ViewState) -> ViewState {
        switch viewState {
        case .loading:
            .loading
        case .failedToLoad(let error):
            .failedToLoad(error: error)
        case .loaded:
            .loaded(filteredCollections(entry: searchEntry))
        }
    }

    private func updateState(with result: ManagerStateMappingResult) {
        let currentCollections = state.value ?? []

        // We don't need error here, NSError used to silence the compiler
        let errorState = ViewState.failedToLoad(error: NSError(domain: "", code: 0))

        switch result.viewState {
        case .loaded(let collections) where didHaveErrorsWithEmptyCollections(result) && (state.isLoading || currentCollections.isEmpty):
            state = errorState

        case .loaded(let collections) where didHaveErrorsWithEmptyCollections(result):
            break // Keep previous state

        case .loaded:
            state = .loaded(filteredCollections(entry: searchEntry))

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
            .sorted { lhs, rhs in
                if lhs.id.chain.id.caseInsensitiveEquals(to: rhs.id.chain.id) {
                    return lhs.name.caseInsensitiveSmaller(than: rhs.name)
                }
                return lhs.id.chain.id.caseInsensitiveSmaller(than: rhs.id.chain.id)
            }
            .map { collection in
                NFTCompactCollectionViewModel(
                    nftCollection: collection,
                    assetsState: collection.assets.isEmpty ? .loading : .loaded(()),
                    dependencies: dependencies,
                    openAssetDetailsAction: { [weak self] asset in
                        self?.openAssetDetails(for: asset, in: collection)
                    },
                    onCollectionTap: { [weak self] collection, isExpanded in
                        self?.onCollectionTap(collection: collection, isExpanded: isExpanded)
                    }
                )
            }
    }

    private func filterAndAssignCollections(for entry: String) {
        guard case .loaded = state else { return }
        state = .loaded(filteredCollections(entry: entry))
    }

    private func filteredCollections(entry: String) -> [NFTCompactCollectionViewModel] {
        guard entry.isNotEmpty else {
            return collectionsViewModels
        }

        let filteredCollections = collectionsViewModels.filter { collection in
            let collectionNameMatches = collection.name.localizedStandardContains(entry)
            var someAssetsNamesMatch: Bool {
                let assetsViewModels = collection.viewState.value?.assetsViewModels ?? []

                return assetsViewModels.contains { assetsViewModel in
                    return assetsViewModel.state.viewData?.name.localizedStandardContains(entry) ?? false
                }
            }

            return collectionNameMatches || someAssetsNamesMatch
        }

        return filteredCollections
    }

    private func openAssetDetails(for asset: NFTAsset, in collection: NFTCollection) {
        coordinator?.openAssetDetails(for: asset, in: collection, navigationContext: navigationContext)
        dependencies.analytics.logDetailsOpen(dependencies.nftChainNameProviding.provide(for: asset.id.chain))
    }

    private func onCollectionTap(collection: NFTCollection, isExpanded: Bool) {
        // We don't need to scroll if collection is collapsed
        tappedRowID = isExpanded ? collection.id : nil

        if shouldLoadAssets(for: collection, isExpanded: isExpanded) {
            nftManager.updateAssets(in: collection)
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

    private func didHaveErrorsWithEmptyCollections(
        _ result: ManagerStateMappingResult
    ) -> Bool {
        result.notificationViewData != nil &&
            result.viewState.value?.isEmpty ?? false
    }
}

// MARK: - Helpers

private extension NFTCollectionsListViewModel {
    struct ManagerStateMappingResult {
        let viewState: ViewState
        let notificationViewData: NFTNotificationViewData?
    }
}

// MARK: - Constants

private extension NFTCollectionsListViewModel {
    enum Constants {
        /// Delay (in seconds) before updating the list of NFT collections after sending an NFT asset.
        static let assetSendUpdateDelay: DispatchQueue.SchedulerTimeType.Stride = 1.0
    }
}
