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
final class EarnDetailViewModel: MarketsBaseViewModel {
    // MARK: - Injected & Published Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published Properties

    @Published private(set) var mostlyUsedViewModels: [EarnTokenItemViewModel] = []
    @Published private(set) var listLoadingState: EarnBestOpportunitiesListView.LoadingState = .loading
    @Published private(set) var tokenViewModels: [EarnTokenItemViewModel] = []

    // MARK: - Private Properties

    private let filterProvider: EarnDataFilterProvider
    private let dataProvider: EarnDataProvider
    private let analyticsProvider: EarnAnalyticsProvider

    private weak var coordinator: EarnDetailRoutable?

    private var userWalletModels: [UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        dataProvider: EarnDataProvider,
        filterProvider: EarnDataFilterProvider,
        mostlyUsedTokens: [EarnTokenModel],
        coordinator: EarnDetailRoutable? = nil,
        analyticsProvider: EarnAnalyticsProvider
    ) {
        self.dataProvider = dataProvider
        self.filterProvider = filterProvider
        self.coordinator = coordinator
        self.analyticsProvider = analyticsProvider

        super.init(overlayContentProgressInitialValue: 1.0)

        setupMostlyUsedViewModels(from: mostlyUsedTokens)
        bind()

        fetch(with: filterProvider.currentFilter)
        filterProvider.fetchAvailableNetworks()
    }

    // MARK: - Public Methods

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

    func onMostlyUsedScrolledToFourthItem() {
        analyticsProvider.logMostlyUsedCarouselScrolled()
    }

    // MARK: - Private Implementation

    private func setupMostlyUsedViewModels(from tokens: [EarnTokenModel]) {
        mostlyUsedViewModels = tokens.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                self?.handleTokenTap(token, source: .mostlyUsed)
            }
        }
    }

    private func handleTokenTap(_ token: EarnTokenModel, source: EarnOpportunitySource) {
        analyticsProvider.logOpportunitySelected(
            token: token.symbol,
            blockchain: token.networkName,
            source: source.rawValue
        )
        let resolution = EarnTokenInWalletResolver().resolve(earnToken: token, userWalletModels: userWalletModels)
        coordinator?.routeOnTokenResolved(resolution, source: source)
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

    private func fetch(with filter: EarnDataFilter) {
        dataProvider.fetch(with: filter)
    }

    private func appendTokenViewModels(from models: [EarnTokenModel], lastPage: Bool) {
        let newViewModels = models.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                self?.handleTokenTap(token, source: .bestOpportunity)
            }
        }
        tokenViewModels.append(contentsOf: newViewModels)

        if tokenViewModels.isEmpty {
            listLoadingState = .noResults
        } else {
            listLoadingState = lastPage ? .allDataLoaded : .idle
        }
    }

    private func handleDataProviderEvent(_ event: EarnDataProvider.Event) {
        switch event {
        case .loading:
            if tokenViewModels.isEmpty {
                listLoadingState = .loading
            }
        case .idle:
            break
        case .failedToFetchData(let error):
            if tokenViewModels.isEmpty {
                listLoadingState = .error
            }
            let params = error.marketsAnalyticsParams
            let errorCode = params[.errorCode] ?? ""
            let errorMessage = params[.errorMessage] ?? ""
            if mostlyUsedViewModels.isEmpty {
                analyticsProvider.logPageLoadError(errorCode: errorCode, errorMessage: errorMessage)
            } else {
                analyticsProvider.logBestOpportunitiesLoadError(errorCode: errorCode, errorMessage: errorMessage)
            }
        case .appendedItems(let models, let lastPage):
            appendTokenViewModels(from: models, lastPage: lastPage)
        case .startInitialFetch, .cleared:
            tokenViewModels = []
            listLoadingState = .loading
        }
    }
}

// MARK: - Filter State

extension EarnDetailViewModel {
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
