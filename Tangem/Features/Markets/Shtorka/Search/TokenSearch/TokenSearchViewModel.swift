//
//  TokenSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// [STUB] Delete this comment when implemented.
///
/// TokenSearchViewModel orchestrates the token search flow for redesign.
/// It replaces the search portion of MarketsMainViewModel when redesign is enabled.
///
/// Responsibilities:
///   1. Subscribe to MainBottomSheetHeaderViewModel.enteredSearchInputPublisher
///   2. On text input: run local search instantly (< 100ms) via UserAssetsSearchProvider,
///      then debounced (300ms) API search via MarketsListDataProvider
///   3. On "Search/Enter" key: bypass debounce, fire API request immediately
///   4. Handle race conditions: ignore stale API responses if a newer request was sent
///   5. Aggregate results into screenState for the View to render
///   6. On result tap: save to recents via TokenSearchStorage (publisher updates automatically)
///   7. On clear/cancel: reset to .idle
///
/// isSearching ownership:
///   TokenSearchViewModel publishes its own isSearching state.
///   MarketsMainViewModel reads it to drive showSearchResult in the View.
///   When redesign is ON, MarketsMainViewModel should NOT run its own searchTextBind() —
///   TokenSearchViewModel fully owns the search subscription to avoid duplicate API calls.
///
/// Key constraint: search text must NEVER be logged to analytics or console (privacy, see NFR spec)
final class TokenSearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var screenState: TokenSearchScreenState = .idle
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var recentItems: [TokenSearchRecentItem] = []
    @Published private(set) var result: TokenSearchResult?

    // MARK: - Dependencies

    let headerViewModel: MainBottomSheetHeaderViewModel

    private let storage: any TokenSearchStorage
    private let userAssetsProvider: any UserAssetsSearchProviding
    private weak var coordinator: MarketsRoutable?

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        headerViewModel: MainBottomSheetHeaderViewModel,
        storage: some TokenSearchStorage = StubTokenSearchStorage(),
        userAssetsProvider: some UserAssetsSearchProviding = StubUserAssetsSearchProvider(),
        coordinator: MarketsRoutable? = nil
    ) {
        self.headerViewModel = headerViewModel
        self.storage = storage
        self.userAssetsProvider = userAssetsProvider
        self.coordinator = coordinator

        bind()
    }

    // MARK: - Actions

    /// User tapped a market asset in search results or in the Recents block.
    /// Saves the search query + asset to recents, then navigates to Market Token Details.
    func onMarketAssetTapped(tokenModel: MarketsTokenModel) {
        let query = headerViewModel.enteredSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            if query.isNotEmpty { await storage.saveQuery(query) }
            await storage.saveMarketAsset(tokenModel)
        }
        coordinator?.openMarketsTokenDetails(for: tokenModel)
    }

    /// User tapped a user portfolio asset in search results.
    /// Saves the search query to recents (asset itself is NOT saved to recents per BF-10).
    func onUserAssetTapped() {
        let query = headerViewModel.enteredSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isNotEmpty {
            Task { await storage.saveQuery(query) }
        }

        // [STUB] Navigate to Token Details — needs coordinator method for user assets
    }

    func onClearAllHistory() {
        Task { await storage.clearAll() }
    }

    func onShowMoreUserAssets() {
        // [STUB] Delete this body when implemented.
        // Rebuild result with isUserAssetsCollapsed = false
    }

    func onRetryMarketSearch() {
        // [STUB] Delete this body when implemented.
        // Re-fire the last API request for market assets
    }

    // MARK: - Private

    private func bind() {
        bindRecentItems()

        // [STUB] Delete the comment below when implemented.
        // Subscribe to headerViewModel.enteredSearchInputPublisher:
        //   .textInput(value) → run local search instantly, debounce(300ms) API search
        //   .clearInput / .cancelInput → reset to .idle
        //
        // Race condition handling:
        //   Use switchToLatest or request ID tracking to ignore stale API responses
    }

    private func bindRecentItems() {
        storage.recentItemsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, items in
                viewModel.recentItems = items
            }
            .store(in: &bag)
    }
}
