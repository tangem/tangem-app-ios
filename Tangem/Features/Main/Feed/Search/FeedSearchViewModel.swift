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

    private var history: FeedSearchHistory = .empty
    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        tabsViewModel: FeedSearchTabsViewModel,
        historyProvider: FeedSearchHistoryProvider,
        marketViewModel: CryptoSearchViewModel
    ) {
        self.searchBarViewModel = searchBarViewModel
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
        isActive = true
        syncVisibility()
    }

    func close() {
        guard isActive else {
            return
        }

        isActive = false
        syncVisibility()
    }

    func reset() {
        // Keep the outgoing results stable during their exit animation; the next search starts with a blank query.
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
            .map { $0.trimmed().isEmpty }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, isBlank in
                viewModel.onQueryBlankChange(isBlank)
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
