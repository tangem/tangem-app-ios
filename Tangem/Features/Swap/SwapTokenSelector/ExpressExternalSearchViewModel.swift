//
//  ExpressExternalSearchViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class ExpressExternalSearchViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var state: State = .idle

    // MARK: - Dependencies

    private let searchProvider: ExpressSearchTokensProvider
    private let chartsProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider
    private let marketCapFormatter: MarketCapFormatter

    private var currentTask: Task<Void, Never>?
    private var searchCancellable: AnyCancellable?

    private weak var selectionHandler: ExpressExternalTokenSelectionHandler?

    private var currentSearchText: String = ""

    // MARK: - Init

    init(searchProvider: ExpressSearchTokensProvider) {
        self.searchProvider = searchProvider

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

    func setup(selectionHandler: ExpressExternalTokenSelectionHandler?) {
        self.selectionHandler = selectionHandler
    }

    func onAppear() {
        // Load trending on first appear if no search text
        if currentSearchText.isEmpty, case .idle = state {
            loadTrending()
        }
    }

    // MARK: - Private

    private func handleSearchTextChange(_ text: String) {
        currentSearchText = text

        if text.isEmpty {
            loadTrending()
        } else if text.count >= 2 {
            performSearch(text: text)
        } else {
            // 1 character - show idle state
            currentTask?.cancel()
            state = .idle
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

extension ExpressExternalSearchViewModel {
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

// MARK: - ExpressExternalTokenSelectionHandler

protocol ExpressExternalTokenSelectionHandler: AnyObject {
    func didSelectExternalToken(_ token: MarketsTokenModel)
}
