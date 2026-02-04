//
//  EarnDetailViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class EarnDetailViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published private(set) var mostlyUsedViewModels: [EarnTokenItemViewModel] = []
    @Published private(set) var listLoadingState: EarnBestOpportunitiesListView.LoadingState = .loading
    @Published private(set) var tokenViewModels: [EarnTokenItemViewModel] = []

    var isFilterInteractionEnabled: Bool {
        filterProvider.state == .loaded
    }

    var isFilterLoading: Bool {
        filterProvider.state == .loading
    }

    var selectedNetworkFilterTitle: String {
        filterProvider.selectedNetworkFilter.displayTitle
    }

    var selectedFilterTypeTitle: String {
        filterProvider.selectedFilterType.description
    }

    var hasActiveFilters: Bool {
        filterProvider.hasActiveFilters
    }

    // MARK: - Private Properties

    private let filterProvider: EarnDataFilterProvider

    private let dataProvider = EarnDataProvider()
    private weak var coordinator: EarnDetailRoutable?

    private var userWalletModels: [UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        filterProvider: EarnDataFilterProvider,
        mostlyUsedTokens: [EarnTokenModel],

        coordinator: EarnDetailRoutable? = nil
    ) {
        self.filterProvider = filterProvider
        self.coordinator = coordinator

        setupMostlyUsedViewModels(from: mostlyUsedTokens)
        bind()

        fetch(with: filterProvider.currentFilter)
    }

    // MARK: - Public Methods

    func onAppear() {
        Task {
            await filterProvider.fetchAvailableNetworks()
        }
    }

    func onRetry() {
        fetch(with: filterProvider.currentFilter)
    }

    func clearFilters() {
        filterProvider.clear()
    }

    var canFetchMore: Bool {
        dataProvider.canFetchMore
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    // MARK: - Private Implementation

    private func setupMostlyUsedViewModels(from tokens: [EarnTokenModel]) {
        mostlyUsedViewModels = tokens.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                guard let self else { return }
                coordinator?.openAddEarnToken(for: token, userWalletModels: userWalletModels)
            }
        }
    }

    private func bind() {
        filterProvider.filterPublisher
            .dropFirst()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.fetch(with: filter)
            }
            .store(in: &bag)

        let loadedFilterStatePublisher = filterProvider.statePublisher
            .filter { $0 != .idle }
            .filter { $0 != .loading }
            .first()

        dataProvider.eventPublisher
            .combineLatest(loadedFilterStatePublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, args in
                let (event, _) = args
                viewModel.handleDataProviderEvent(event)
            }
            .store(in: &bag)
    }

    private func fetch(with filter: EarnDataProvider.Filter) {
        dataProvider.fetch(with: filter)
    }

    private func handleDataProviderEvent(_ event: EarnDataProvider.Event) {
        switch event {
        case .loading:
            if tokenViewModels.isEmpty {
                listLoadingState = .loading
            }
        case .idle:
            break
        case .failedToFetchData:
            if tokenViewModels.isEmpty {
                listLoadingState = .error
            }
        case .appendedItems(let models, let lastPage):
            let newViewModels = models.map { token in
                EarnTokenItemViewModel(token: token) { [weak self] in
                    guard let self else { return }
                    coordinator?.openAddEarnToken(for: token, userWalletModels: userWalletModels)
                }
            }
            tokenViewModels.append(contentsOf: newViewModels)

            if tokenViewModels.isEmpty {
                listLoadingState = .noResults
            } else {
                listLoadingState = lastPage ? .allDataLoaded : .idle
            }
        case .startInitialFetch, .cleared:
            tokenViewModels = []
            listLoadingState = .loading
        }
    }
}

// MARK: - View Action

extension EarnDetailViewModel {
    func handleViewAction(_ viewAction: ViewAction) {
        switch viewAction {
        case .back:
            coordinator?.dismiss()
        case .networksFilterTap:
            coordinator?.openNetworksFilter()
        case .typesFilterTap:
            coordinator?.openTypesFilter()
        }
    }

    enum ViewAction {
        case back
        case networksFilterTap
        case typesFilterTap
    }
}
