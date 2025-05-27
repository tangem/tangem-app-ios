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
    private let navigationContext: NFTNavigationContext
    private let dependencies: NFTCollectionsListDependencies
    private let assetSendPublisher: AnyPublisher<NFTAsset, Never>

    // MARK: Properties

    private var collectionsViewModels: [NFTCompactCollectionViewModel] = []
    private var bag = Set<AnyCancellable>()
    private weak var coordinator: NFTCollectionsListRoutable?
    private var pullToRefreshCompletion: (() -> Void)?

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

        bind()
    }

    func onReceiveButtonTap() {
        coordinator?.openReceive(navigationContext: navigationContext)
    }

    func update(completion: (() -> Void)? = nil) {
        pullToRefreshCompletion = completion
        guard !state.isLoading else { return }
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
                if let completion = viewModel.pullToRefreshCompletion {
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
                notificationViewData: nil
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
        case .loaded(let collections):
            .loaded(filteredCollections(entry: searchEntry))
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
            break // Keep previous state (non-loading)

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

// MARK: - Constants

private extension NFTCollectionsListViewModel {
    struct Constants {
        /// Delay (in seconds) before updating the list of NFT collections after sending an NFT asset.
        static let assetSendUpdateDelay: DispatchQueue.SchedulerTimeType.Stride = 1.0
    }
}
