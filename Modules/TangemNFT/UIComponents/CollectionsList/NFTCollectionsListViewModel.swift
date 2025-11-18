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
import TangemUI

public final class NFTCollectionsListViewModel: ObservableObject {
    typealias ViewState = LoadingValue<[NFTCollectionDisclosureGroupViewModel]>

    // MARK: State

    /// - Warning: Should never be mutated directly, use `updateState(to:)` method instead.
    @Published private(set) var state: ViewState = .loading
    @Published var searchEntry: String = ""
    @Published private(set) var isShimmerActive = false
    @Published private(set) var rowExpanded = false
    @Published private(set) var tappedRowID: AnyHashable? = nil
    @Published private(set) var loadingTroublesViewData: NFTNotificationViewData?
    private(set) lazy var scrollViewStateObject: RefreshScrollViewStateObject = .init(refreshable: { [weak self] in
        await withCheckedContinuation { [weak self] pullToRefreshContinuation in
            guard self?.state.isLoading == false else {
                self?.pullToRefreshContinuation?.resume()
                return
            }

            self?.pullToRefreshContinuation = pullToRefreshContinuation
            self?.updateInternal()
        }
    })

    // MARK: - Private properties

    private lazy var stateUpdater = NFTCollectionsListStateUpdater(
        loadingStateStartThreshold: Constants.loadingStateStartThreshold,
        loadingStateMinDuration: Constants.loadingStateMinDuration,
        onStateChange: { [weak self] newValue in
            self?.state = newValue
        }
    )

    private var collectionsViewModels: [NFTCollectionDisclosureGroupViewModel] = []
    private var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    private var didAppear = false
    private var bag: Set<AnyCancellable> = []

    // MARK: Dependencies

    private let nftManager: NFTManager
    // [REDACTED_TODO_COMMENT]
    private let accounForNFTCollectionsProvider: AccountForNFTCollectionProviding
    private let navigationContext: NFTNavigationContext
    private let dependencies: NFTCollectionsListDependencies
    private let assetSendPublisher: AnyPublisher<NFTAsset, Never>
    private weak var coordinator: NFTCollectionsListRoutable?

    public init(
        nftManager: NFTManager,
        accounForNFTCollectionsProvider: AccountForNFTCollectionProviding,
        navigationContext: NFTNavigationContext,
        dependencies: NFTCollectionsListDependencies,
        assetSendPublisher: AnyPublisher<NFTAsset, Never>,
        coordinator: NFTCollectionsListRoutable?
    ) {
        self.nftManager = nftManager
        self.accounForNFTCollectionsProvider = accounForNFTCollectionsProvider
        self.coordinator = coordinator
        self.dependencies = dependencies
        self.assetSendPublisher = assetSendPublisher
        self.navigationContext = navigationContext
    }

    deinit {
        pullToRefreshContinuation?.resume()
    }

    func onViewAppear() {
        if didAppear {
            return
        }

        didAppear = true
        bind()
        updateInternal(isInitialUpdate: true)
    }

    func onReceiveButtonTap() {
        coordinator?.openReceive(navigationContext: navigationContext)
        dependencies.analytics.logReceiveOpen()
    }

    func update() {
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

    func isStateEmpty(collections: [NFTCollectionDisclosureGroupViewModel]) -> Bool {
        collections.isEmpty && searchEntry.isEmpty
    }

    private func bind() {
        nftManager
            .statePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, managerState in
                return viewModel.map(managerState: managerState)
            }
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, result in
                viewModel.collectionsViewModels = result.viewState.value ?? []
                viewModel.loadingTroublesViewData = result.notificationViewData
                viewModel.updateState(with: result)
                viewModel.updatePullToRefreshCompletion(with: result)
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

    private func updateInternal(isInitialUpdate: Bool = false) {
        // Fetching the cached data, if available, on initial update
        if isInitialUpdate {
            nftManager.update(cachePolicy: .always)
        }
        nftManager.update(cachePolicy: .never)
    }

    private func updatePullToRefreshCompletion(with result: ManagerStateMappingResult) {
        guard let continuation = pullToRefreshContinuation,
              !result.viewState.isLoading else {
            return
        }

        continuation.resume()
        pullToRefreshContinuation = nil
    }

    private func updateState(to newValue: ViewState) {
        stateUpdater.updateState(to: newValue)
    }

    private func updateState(with result: ManagerStateMappingResult) {
        isShimmerActive = false
        // Since we are using the state queue, we need to access the most recent state here (`stateUpdater.mostRecentState`)
        let currentCollections = stateUpdater.mostRecentState?.value ?? state.value ?? []

        switch result.viewState {
        case .loaded where didHaveErrorsWithEmptyCollections(result) && (state.isLoading || currentCollections.isEmpty):
            // We don't need error here, NSError used to silence the compiler
            updateState(to: .failedToLoad(error: NSError.dummy))

        case .loaded where didHaveErrorsWithEmptyCollections(result):
            break // Keep previous state

        case .loaded:
            updateState(to: .loaded(filteredCollections(entry: searchEntry)))

        case .loading where currentCollections.isEmpty:
            updateState(to: .loading)

        case .loading:
            isShimmerActive = true // Keep previous state and start shimmer animation

        case .failedToLoad(let error):
            updateState(to: .failedToLoad(error: error))
        }
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
            let loadingTroublesViewData = collectionsResult.hasErrors ? makeNotificationViewData() : nil
            return .init(
                viewState: .loaded(buildCollections(from: collectionsResult.value)),
                notificationViewData: loadingTroublesViewData
            )
        }
    }

    private func buildCollections(from collections: [NFTCollection]) -> [NFTCollectionDisclosureGroupViewModel] {
        collections
            .sorted { lhs, rhs in
                if lhs.id.chain.id.caseInsensitiveEquals(to: rhs.id.chain.id) {
                    return lhs.name.caseInsensitiveSmaller(than: rhs.name)
                }
                return lhs.id.chain.id.caseInsensitiveSmaller(than: rhs.id.chain.id)
            }
            .map { collection in
                let assetsResult = collection.assetsResult

                let assetsState: NFTCollectionDisclosureGroupViewModel.AssetsState = if assetsResult.hasErrors, assetsResult.value.isEmpty {
                    .failedToLoad(error: NSError.dummy)
                } else if assetsResult.value.isNotEmpty {
                    .loaded(assetsResult.value)
                } else {
                    .loading
                }

                return NFTCollectionDisclosureGroupViewModel(
                    nftCollection: collection,
                    assetsState: assetsState,
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
        updateState(to: .loaded(filteredCollections(entry: entry)))
    }

    private func filteredCollections(entry: String) -> [NFTCollectionDisclosureGroupViewModel] {
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

    private func shouldLoadAssets(for collection: NFTCollection, isExpanded: Bool) -> Bool {
        let noAssetsLoaded = collection.assetsResult.value.isEmpty

        return noAssetsLoaded && isExpanded
    }

    private func didHaveErrorsWithEmptyCollections(_ result: ManagerStateMappingResult) -> Bool {
        result.notificationViewData != nil && result.viewState.value?.isEmpty ?? false
    }

    private func onCollectionTap(collection: NFTCollection, isExpanded: Bool) {
        // We don't need to scroll if collection is collapsed
        tappedRowID = isExpanded ? collection.id : nil

        if shouldLoadAssets(for: collection, isExpanded: isExpanded) {
            nftManager.updateAssets(in: collection)
        }
    }

    private func openAssetDetails(for asset: NFTAsset, in collection: NFTCollection) {
        coordinator?.openAssetDetails(for: asset, in: collection, navigationContext: navigationContext)
        dependencies.analytics.logDetailsOpen(
            dependencies.nftChainNameProviding.provide(for: asset.id.chain),
            asset.id.contractType.description
        )
    }

    private func makeNotificationViewData() -> NFTNotificationViewData {
        NFTNotificationViewData(
            title: Localization.nftCollectionsWarningTitle,
            subtitle: Localization.nftCollectionsWarningSubtitle,
            icon: Assets.warningIcon
        )
    }
}

// MARK: - Auxiliary types

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
        static let loadingStateStartThreshold: TimeInterval = 0.1
        static let loadingStateMinDuration: TimeInterval = 1.0
    }
}
