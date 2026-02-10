//
//  SwapMarketsTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class SwapMarketsTokensViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var state: State = .idle

    // MARK: - Dependencies

    private let searchProvider: SwapMarketsTokensProvider
    private let chartsProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider
    private let marketCapFormatter: MarketCapFormatter
    private let configuration: Configuration

    private var currentTask: Task<Void, Never>?
    private var searchCancellable: AnyCancellable?
    private var activeCancellable: AnyCancellable?

    private weak var selectionHandler: SwapMarketsTokenSelectionHandler?

    private var currentSearchText: String = ""
    private var isActive: Bool = true

    // MARK: - Init

    init(
        searchProvider: SwapMarketsTokensProvider,
        configuration: Configuration = .withTrending
    ) {
        self.searchProvider = searchProvider
        self.configuration = configuration

        chartsProvider = MarketsListChartsHistoryProvider()
        filterProvider = MarketsListDataFilterProvider()
        marketCapFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: .init()
        )
    }

    // MARK: - Setup

    func setup(searchTextPublisher: some Publisher<String, Never>) {
        searchCancellable = searchTextPublisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.handleSearchTextChange(text)
            }
    }

    func setup(selectionHandler: SwapMarketsTokenSelectionHandler?) {
        self.selectionHandler = selectionHandler
    }

    func setup(isActivePublisher: some Publisher<Bool, Never>) {
        activeCancellable = isActivePublisher
            .removeDuplicates()
            .sink { [weak self] isActive in
                guard let self else { return }

                self.isActive = isActive
                if isActive {
                    // When becoming active, trigger search if there's already text in the search field
                    if !currentSearchText.isEmpty {
                        handleSearchTextChange(currentSearchText)
                    }
                } else {
                    currentTask?.cancel()
                    state = .idle
                }
            }
    }

    func onAppear() {
        // Only withTrending mode loads trending on appear
        guard configuration == .withTrending else { return }

        // Load trending on first appear if no search text
        if currentSearchText.isEmpty, case .idle = state {
            loadTrending()
        }
    }

    // MARK: - Private

    private func handleSearchTextChange(_ text: String) {
        currentSearchText = text

        // For searchOnlyOnDemand mode, check if active
        if configuration == .searchOnlyOnDemand, !isActive {
            state = .idle
            return
        }

        if text.isEmpty {
            switch configuration {
            case .withTrending:
                loadTrending()
            case .searchOnlyOnDemand:
                currentTask?.cancel()
                state = .idle
            }
        } else {
            performSearch(text: text)
        }
    }

    private func loadTrending() {
        currentTask?.cancel()
        state = .loading(mode: .trending)

        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let trendingTokens = try await searchProvider.loadTrending()

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    let tokenIds = trendingTokens.map(\.id)
                    self.chartsProvider.fetch(for: tokenIds, with: self.filterProvider.currentFilterValue.interval)

                    let viewModels = trendingTokens.map { token in
                        self.makeItemViewModel(token: token)
                    }
                    self.state = .loaded(tokens: viewModels, mode: .trending)
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.state = .idle
                }
            }
        }
    }

    private func performSearch(text: String) {
        currentTask?.cancel()
        state = .loading(mode: .search)

        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let searchResults = try await searchProvider.search(text: text)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    let tokenIds = searchResults.map(\.id)
                    self.chartsProvider.fetch(for: tokenIds, with: self.filterProvider.currentFilterValue.interval)

                    let viewModels = searchResults.map { token in
                        self.makeItemViewModel(token: token)
                    }

                    if viewModels.isEmpty {
                        self.state = .noResults
                    } else {
                        self.state = .loaded(tokens: viewModels, mode: .search)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.state = .idle
                }
            }
        }
    }

    private func makeItemViewModel(token: MarketsTokenModel) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: token,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.selectionHandler?.didSelectExternalToken(token)
            }
        )
    }
}

// MARK: - State

extension SwapMarketsTokensViewModel {
    /// Returns true if markets section has visible content (loading, trending, or search results)
    /// Used to determine if the parent view should hide its "no results" empty state
    var hasVisibleContent: Bool {
        switch state {
        case .idle, .noResults:
            return false
        case .loading, .loaded:
            return true
        }
    }

    enum Configuration {
        /// Shows trending on appear + search
        case withTrending
        /// Only shows search results when actively searching
        case searchOnlyOnDemand
    }

    enum State: Equatable {
        case idle
        case loading(mode: Mode)
        case loaded(tokens: [MarketTokenItemViewModel], mode: Mode)
        case noResults

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.noResults, .noResults):
                return true
            case (.loading(let lhsMode), .loading(let rhsMode)):
                return lhsMode == rhsMode
            case (.loaded(let lhsTokens, let lhsMode), .loaded(let rhsTokens, let rhsMode)):
                return lhsTokens.map(\.id) == rhsTokens.map(\.id) && lhsMode == rhsMode
            default:
                return false
            }
        }
    }

    enum Mode: Equatable {
        case trending
        case search

        var title: String {
            switch self {
            case .trending:
                return Localization.marketsSortByTrendingTitle
            case .search:
                return Localization.commonFeeSelectorOptionMarket
            }
        }

        var showsTokenCount: Bool {
            switch self {
            case .trending:
                return false
            case .search:
                return true
            }
        }
    }
}

// MARK: - SwapMarketTokenSelectionHandler

protocol SwapMarketsTokenSelectionHandler: AnyObject {
    func didSelectExternalToken(_ token: MarketsTokenModel)
}
