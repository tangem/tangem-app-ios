//
//  FeedSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class FeedSearchViewModel: ObservableObject {
    @Published private(set) var state: FeedSearchState = .suggestions(.empty)
    @Published private(set) var isActive = false

    let searchBarViewModel: FeedSearchBarViewModel
    let tabsViewModel: FeedSearchTabsViewModel
    let marketViewModel: CryptoSearchViewModel

    private let historyProvider: FeedSearchHistoryProvider
    private let resultsQuery: CurrentValueSubject<String, Never>

    private var history: FeedSearchHistory = .empty
    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        resultsQuery: CurrentValueSubject<String, Never>,
        tabsViewModel: FeedSearchTabsViewModel,
        historyProvider: FeedSearchHistoryProvider,
        marketViewModel: CryptoSearchViewModel
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.resultsQuery = resultsQuery
        self.tabsViewModel = tabsViewModel
        self.historyProvider = historyProvider
        self.marketViewModel = marketViewModel

        bind()
    }

    deinit {
        AppLogger.debug("FeedSearchViewModel deinit")
    }

    func open() {
        guard !isActive else {
            return
        }

        searchBarViewModel.query = ""
        resultsQuery.send("")
        state = .suggestions(history)
        isActive = true
        syncVisibility()
    }

    func close() {
        isActive = false
        syncVisibility()
        searchBarViewModel.query = ""
    }

    func reset() {
        close()
    }

    func onSelectRecentQuery(_ query: FeedRecentQuery) {
        searchBarViewModel.query = query.value
    }

    func onRemoveRecentQuery(_ query: FeedRecentQuery) {
        historyProvider.remove(query)
    }
}

// MARK: - Binding

private extension FeedSearchViewModel {
    func bind() {
        searchBarViewModel
            .queryPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                guard viewModel.isActive else { return }

                viewModel.resultsQuery.send(query)
                viewModel.onQueryBlankChange(query.trimmed().isEmpty)
            }
            .store(in: &bag)

        searchBarViewModel
            .submitPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.historyProvider.save(query: viewModel.searchBarViewModel.query)
            }
            .store(in: &bag)

        historyProvider
            .historyPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, history in
                viewModel.history = history
                viewModel.refreshSuggestionsState()
            }
            .store(in: &bag)
    }
}

// MARK: - State

private extension FeedSearchViewModel {
    func onQueryBlankChange(_ isBlank: Bool) {
        switch (isBlank, state) {
        case (true, .suggestions), (false, .tabs): return
        default: break
        }

        state = isBlank ? .suggestions(history) : .tabs
        syncVisibility()
    }

    func refreshSuggestionsState() {
        guard case .suggestions = state else {
            return
        }

        state = .suggestions(history)
    }

    func syncVisibility() {
        let isSearching: Bool

        switch state {
        case .tabs: isSearching = isActive
        case .suggestions: isSearching = false
        }

        tabsViewModel.setSearching(isSearching)
        marketViewModel.setVisible(isActive && !isSearching)
    }
}
