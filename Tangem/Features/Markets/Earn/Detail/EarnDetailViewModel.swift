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
    // MARK: - Published Properties

    @Published private(set) var mostlyUsedViewModels: [EarnTokenItemViewModel] = []
    @Published private(set) var bestOpportunitiesResultState: LoadingResult<[EarnTokenItemViewModel], Error> = .loading
    @Published private(set) var currentFilterType: EarnFilterType = .all
    @Published private(set) var currentNetworkFilter: EarnNetworkFilterType = .all

    // MARK: - Private Properties

    private let dataProvider = EarnDataProvider()
    private let filterProvider = EarnDataFilterProvider(initialFilterType: .all, initialNetworkFilter: .userNetworks)
    private weak var coordinator: EarnDetailRoutable?

    private var accumulatedOpportunities: [EarnTokenItemViewModel] = []
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        mostlyUsedTokens: [EarnTokenModel],
        coordinator: EarnDetailRoutable? = nil
    ) {
        self.coordinator = coordinator
        setupMostlyUsedViewModels(from: mostlyUsedTokens)
        bind()
    }

    // MARK: - Private Implementation

    private func setupMostlyUsedViewModels(from tokens: [EarnTokenModel]) {
        mostlyUsedViewModels = tokens.map { token in
            EarnTokenItemViewModel(token: token) { [weak self] in
                self?.coordinator?.openEarnTokenDetails(for: token)
            }
        }
    }

    private func bind() {
        filterProvider.filterPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.currentFilterType = viewModel.filterProvider.selectedFilterType
                viewModel.currentNetworkFilter = viewModel.filterProvider.selectedNetworkFilter
                viewModel.dataProvider.fetch(with: filter)
            }
            .store(in: &bag)

        dataProvider.eventPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                viewModel.handleDataProviderEvent(event)
            }
            .store(in: &bag)
    }

    private func handleDataProviderEvent(_ event: EarnDataProvider.Event) {
        switch event {
        case .loading:
            if accumulatedOpportunities.isEmpty {
                bestOpportunitiesResultState = .loading
            }
        case .idle:
            break
        case .failedToFetchData(let error):
            bestOpportunitiesResultState = .failure(error)
        case .appendedItems(let models, let lastPage):
            let newViewModels = models.map { token in
                EarnTokenItemViewModel(token: token) { [weak self] in
                    self?.coordinator?.openEarnTokenDetails(for: token)
                }
            }
            accumulatedOpportunities.append(contentsOf: newViewModels)
            bestOpportunitiesResultState = .success(accumulatedOpportunities)
        case .startInitialFetch:
            accumulatedOpportunities = []
            bestOpportunitiesResultState = .loading
        case .cleared:
            accumulatedOpportunities = []
            bestOpportunitiesResultState = .loading
        }
    }

    func loadBestOpportunities() {
        dataProvider.fetch(with: filterProvider.currentFilter)
    }

    func retryBestOpportunities() {
        dataProvider.fetch(with: filterProvider.currentFilter)
    }

    var canFetchMore: Bool {
        dataProvider.canFetchMore
    }

    func fetchMore() {
        dataProvider.fetchMore()
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

// MARK: - Filter actions (for filter sheets / future use)

extension EarnDetailViewModel {
    func handleFilterTypeSelection(_ type: EarnFilterType) {
        filterProvider.didSelectFilterType(type)
    }

    func handleNetworkFilterSelection(_ filter: EarnNetworkFilterType) {
        filterProvider.didSelectNetworkFilter(filter)
    }

    func setUserNetworkIds(_ ids: [String]?) {
        filterProvider.setUserNetworkIds(ids)
    }
}
