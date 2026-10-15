//
//  CollectiblesMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUIUtils
import Foundation
import UIKit

@MainActor
final class CollectiblesMainViewModel: ObservableObject {
    // MARK: - Properties

    let accountViewModel: CollectiblesAccountViewModel
    let loreTabsViewModel: CollectiblesLoreTabsViewModel
    let packsViewModel: CollectiblesPacksViewModel
    let searchResultsViewModel: CollectiblesPacksViewModel

    private var pendingCatalogueSync: Task<Void, Never>?

    private(set) var scrollOffset: CGFloat = 0

    // MARK: - Publishers

    @Published var searchQuery = ""
    @Published var isSearchFieldFocused = false

    @Published private(set) var isTabsPinned = false
    @Published private(set) var isBalanceScrolledAway = false
    @Published private(set) var isSearchAvailable = false
    @Published private(set) var accountBalanceText = ""

    @Published private(set) var isSearching = false
    @Published private(set) var selectedLoreID: String?

    /// Search blanks the account block in place, so the bar carries the balance there from the start.
    var showsBalanceInNavigationBar: Bool {
        isSearching || isBalanceScrolledAway
    }

    var showsSearchBar: Bool {
        isSearching || isSearchAvailable
    }

    // MARK: - Init

    init(
        routable: (any CollectiblesMainRoutable)?,
        accountModel: (any CollectiblesBalanceSource & CollectiblesVaultUsdcAccountProvider)?,
        catalogueProvider: any CollectiblesLoresProvider & CollectiblesPacksProvider = CollectiblesAPIService()
    ) {
        let openMachine: (CollectiblesPack) -> Void = { [weak routable] pack in
            routable?.openMachine(for: pack)
        }

        accountViewModel = CollectiblesAccountViewModel(accountModel: accountModel, routable: routable)
        loreTabsViewModel = CollectiblesLoreTabsViewModel(provider: catalogueProvider)
        packsViewModel = CollectiblesPacksViewModel(
            model: CollectiblesPacksModel(provider: catalogueProvider),
            packSelectionHandler: openMachine
        )
        searchResultsViewModel = CollectiblesPacksViewModel(
            model: CollectiblesPacksModel(provider: catalogueProvider),
            packSelectionHandler: { pack in
                UIApplication.shared.endEditing()
                openMachine(pack)
            }
        )
    }

    deinit {
        pendingCatalogueSync?.cancel()
    }

    // MARK: - Methods

    func observe() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observeAccountBalance() }
            group.addTask { [weak self] in await self?.observeSearchAvailability() }
            group.addTask { [weak self] in await self?.retryTabsOnCatalogueReload() }
            group.addTask { [weak self] in await self?.collapseCatalogueOnTabsFailure() }
            group.addTask { [weak self] in await self?.observeLoreSelection() }
            group.addTask { [weak self] in await self?.observeSearchQuery() }
            group.addTask { [weak self] in await self?.observeSearchFocus() }
        }
    }

    func refresh() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.accountViewModel.refresh() }
            group.addTask { [weak self] in await self?.loreTabsViewModel.refresh() }
            group.addTask { [weak self] in await self?.packsViewModel.refresh() }
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

    func updateBalanceVisibility(balanceMaxY: CGFloat) {
        let threshold = isBalanceScrolledAway ? Constants.balanceShownThreshold : Constants.balanceHiddenThreshold
        let scrolledAway = balanceMaxY < threshold

        if scrolledAway != isBalanceScrolledAway {
            isBalanceScrolledAway = scrolledAway
        }
    }

    func updateScrollOffset(contentMinY: CGFloat) {
        scrollOffset = -contentMinY
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
        for await summary in await accountViewModel.$summary.values {
            guard accountBalanceText != summary.fiatBalancePlainText else { continue }

            accountBalanceText = summary.fiatBalancePlainText
        }
    }

    /// The search spans every machine, so it follows the catalogue's own count rather than the state of
    /// whichever tab is on screen - that one turns over on every switch.
    func observeSearchAvailability() async {
        for await totalPacksCount in await loreTabsViewModel.$totalPacksCount.values {
            let isAvailable = totalPacksCount > 0
            guard isSearchAvailable != isAvailable else { continue }

            isSearchAvailable = isAvailable
        }
    }

    func retryTabsOnCatalogueReload() async {
        for await state in await packsViewModel.$state.values where state.isLoading {
            await loreTabsViewModel.load()
        }
    }

    func collapseCatalogueOnTabsFailure() async {
        for await state in await loreTabsViewModel.$state.values {
            guard case .failed = state, !packsViewModel.state.isFailed else { continue }

            packsViewModel.showFailed()
        }
    }

    func observeLoreSelection() async {
        var currentLoreID = loreTabsViewModel.selectedTab.kind.loreID

        for await tab in await loreTabsViewModel.$selectedTab.values {
            let loreID = tab.kind.loreID
            guard loreID != currentLoreID else { continue }
            currentLoreID = loreID
            selectedLoreID = loreID

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
        case .content:
            searchResultsViewModel.show(packsViewModel.catalogueSnapshot())
        case .empty:
            searchResultsViewModel.showEmpty()
        case .loading, .reloading:
            searchResultsViewModel.showLoading()
            pendingCatalogueSync = Task { [weak self, packsViewModel] in
                _ = await packsViewModel.$state.values.first { !$0.isLoading && !$0.isReloading }

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
        static let balanceHiddenThreshold: CGFloat = 0
        static let balanceShownThreshold: CGFloat = 8
    }
}
