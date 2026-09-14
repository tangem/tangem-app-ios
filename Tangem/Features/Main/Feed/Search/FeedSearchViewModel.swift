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
    @Published private(set) var state: FeedSearchState = .recent(.empty)
    @Published private(set) var isActive = false

    let searchBarViewModel: FeedSearchBarViewModel
    let tabsViewModel: FeedSearchTabsViewModel

    private let historyProvider: FeedSearchHistoryProvider
    private let router: any FeedSearchRoutable

    private var history: FeedSearchHistory = .empty
    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        tabsViewModel: FeedSearchTabsViewModel,
        historyProvider: FeedSearchHistoryProvider,
        router: any FeedSearchRoutable
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.tabsViewModel = tabsViewModel
        self.historyProvider = historyProvider
        self.router = router

        bind()
    }

    deinit {
        AppLogger.debug("FeedSearchViewModel deinit")
    }

    func open() {
        guard !isActive else {
            return
        }

        isActive = true
        syncTabs()
    }

    func close() {
        guard isActive else {
            return
        }

        isActive = false
        syncTabs()
    }

    func reset() {
        close()

        searchBarViewModel.query = ""
    }

    func onSelectRecentToken(_ token: FeedRecentToken) {
        router.openToken(token.model)
    }

    func onSelectRecentQuery(_ query: FeedRecentQuery) {
        searchBarViewModel.query = query.value
    }

    func onRemoveRecentQuery(_ query: FeedRecentQuery) {
        historyProvider.remove(query)
    }

    func onClearRecent() {
        historyProvider.clear()
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
                viewModel.refreshRecentState()
            }
            .store(in: &bag)
    }
}

// MARK: - State

private extension FeedSearchViewModel {
    func onQueryBlankChange(_ isBlank: Bool) {
        state = isBlank ? .recent(history) : .tabs
        syncTabs()
    }

    func refreshRecentState() {
        guard case .recent = state else {
            return
        }

        state = .recent(history)
    }

    func syncTabs() {
        let isSearching: Bool

        switch state {
        case .tabs: isSearching = isActive
        case .recent: isSearching = false
        }

        tabsViewModel.setSearching(isSearching)
    }
}
