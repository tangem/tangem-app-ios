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

final class ExpressExternalSearchViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var searchResults: [MarketTokenItemViewModel] = []
    @Published private(set) var isSearching: Bool = false

    // MARK: - Dependencies

    private let searchProvider: ExpressSearchTokensProvider
    private let chartsProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider
    private let marketCapFormatter: MarketCapFormatter

    private var searchTask: Task<Void, Never>?
    private var searchCancellable: AnyCancellable?

    private weak var selectionHandler: ExpressExternalTokenSelectionHandler?

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
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text: text)
            }
    }

    func setup(selectionHandler: ExpressExternalTokenSelectionHandler?) {
        self.selectionHandler = selectionHandler
    }

    // MARK: - Private

    private func performSearch(text: String) {
        searchTask?.cancel()

        guard text.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }

        // Clear previous results and show loading state
        searchResults = []
        isSearching = true

        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let tokens = try await searchProvider.search(text: text)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    // Fetch chart data for the tokens
                    let tokenIds = tokens.map(\.id)
                    self.chartsProvider.fetch(for: tokenIds, with: self.filterProvider.currentFilterValue.interval)

                    self.searchResults = tokens.map { token in
                        self.makeItemViewModel(token: token)
                    }
                    self.isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
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

// MARK: - ExpressExternalTokenSelectionHandler

protocol ExpressExternalTokenSelectionHandler: AnyObject {
    func didSelectExternalToken(_ token: MarketsTokenModel)
}
