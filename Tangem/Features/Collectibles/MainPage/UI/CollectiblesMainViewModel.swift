//
//  CollectiblesMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import Foundation

@MainActor
final class CollectiblesMainViewModel: ObservableObject {
    // MARK: - Properties

    let accountViewModel = CollectiblesAccountViewModel(provider: CollectiblesAccountSummaryMockProvider())
    let loreTabsViewModel = CollectiblesLoreTabsViewModel(provider: CollectiblesLoresMockProvider())
    let packsViewModel = CollectiblesPacksViewModel(provider: CollectiblesPacksMockProvider())
    let searchResultsViewModel = CollectiblesPacksViewModel(provider: CollectiblesPacksMockProvider())

    private var pendingCatalogueSync: Task<Void, Never>?

    // MARK: - Publishers

    @Published var searchQuery = ""
    @Published var isSearchFieldFocused = false

    @Published private(set) var isTabsPinned = false
    @Published private(set) var isSearchAvailable = false
    /// The balance the navigation bar shows once the account block has scrolled away.
    @Published private(set) var accountBalanceText: String?

    @Published private(set) var isSearching = false

    /// Search blanks the account block in place, so the bar carries the balance there from the start.
    var showsBalanceInNavigationBar: Bool {
        isSearching || isTabsPinned
    }

    var showsSearchBar: Bool {
        isSearching || isSearchAvailable
    }

    deinit {
        pendingCatalogueSync?.cancel()
    }

    // MARK: - Methods

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observeAccountBalance() }
            group.addTask { [weak self] in await self?.observeCatalogueState() }
            group.addTask { [weak self] in await self?.observeLoreSelection() }
            group.addTask { [weak self] in await self?.observeSearchQuery() }
            group.addTask { [weak self] in await self?.observeSearchFocus() }
        }
    }

    func exitSearch() {
        guard isSearching else { return }

        isSearching = false
        isSearchFieldFocused = false
        searchQuery = ""
        cancelPendingCatalogueSync()
        searchResultsViewModel.cancelLoading()
    }

    func updatePinnedState(tabsMinY: CGFloat) {
        let threshold = isTabsPinned ? Constants.tabsUnpinThreshold : Constants.tabsPinThreshold
        let pinned = tabsMinY < threshold
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }
}

// MARK: - Private logic

private extension CollectiblesMainViewModel {
    func observeAccountBalance() async {
        for await state in await accountViewModel.$state.values {
            var text: String?
            if case .content(let summary) = state {
                text = summary.fiatBalanceText
            }
            if accountBalanceText != text {
                accountBalanceText = text
            }
        }
    }

    func observeCatalogueState() async {
        var searchAvailability = isSearchAvailable

        for await state in await packsViewModel.$state.values {
            switch state {
            case .content, .empty:
                searchAvailability = true
            case .failed:
                searchAvailability = false
            case .idle, .loading:
                break
            }
            if isSearchAvailable != searchAvailability {
                isSearchAvailable = searchAvailability
            }
        }
    }

    func observeLoreSelection() async {
        var currentLoreID = loreTabsViewModel.selectedTab.kind.loreID

        for await tab in await loreTabsViewModel.$selectedTab.values {
            let loreID = tab.kind.loreID
            guard loreID != currentLoreID else { continue }
            currentLoreID = loreID

            packsViewModel.reload(loreID: loreID)
            searchResultsViewModel.reset(loreID: loreID)
        }
    }

    func observeSearchQuery() async {
        var currentQuery = searchQuery

        for await query in await $searchQuery.values {
            guard query != currentQuery else { continue }
            currentQuery = query

            guard isSearching else { continue }
            handleSearchQuery(query)
        }
    }

    func observeSearchFocus() async {
        for await isFocused in await $isSearchFieldFocused.values where isFocused {
            enterSearch()
        }
    }

    func enterSearch() {
        guard !isSearching else { return }

        syncSearchResultsWithCatalogue()
        isSearching = true
    }

    func handleSearchQuery(_ query: String) {
        let hasQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
        guard !hasQuery else {
            cancelPendingCatalogueSync()
            searchResultsViewModel.search(query: query)
            return
        }

        syncSearchResultsWithCatalogue()
    }

    func syncSearchResultsWithCatalogue() {
        cancelPendingCatalogueSync()

        switch packsViewModel.state {
        case .content(let models):
            searchResultsViewModel.showContent(models)
        case .empty:
            searchResultsViewModel.showEmpty()
        case .loading:
            searchResultsViewModel.showLoading()
            pendingCatalogueSync = Task { [weak self, packsViewModel] in
                _ = await packsViewModel.$state.values.first { !$0.isLoading }

                guard let self, !Task.isCancelled else { return }
                pendingCatalogueSync = nil
                syncSearchResultsWithCatalogue()
            }
        case .idle, .failed:
            searchResultsViewModel.search(query: "")
        }
    }

    func cancelPendingCatalogueSync() {
        pendingCatalogueSync?.cancel()
        pendingCatalogueSync = nil
    }
}

// MARK: - Constants

private extension CollectiblesMainViewModel {
    enum Constants {
        static let tabsPinThreshold: CGFloat = 0.5
        static let tabsUnpinThreshold: CGFloat = 1.5
    }
}
