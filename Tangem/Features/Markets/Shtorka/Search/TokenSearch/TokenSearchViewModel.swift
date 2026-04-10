//
//  TokenSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// [STUB] Delete this comment when implemented.
///
/// TokenSearchViewModel orchestrates the global search flow for redesign.
/// It replaces the search portion of MarketsMainViewModel when redesign is enabled.
///
/// Responsibilities:
///   1. Subscribe to MainBottomSheetHeaderViewModel.enteredSearchInputPublisher
///   2. On text input: run local search instantly (< 100ms) via UserAssetsSearchProvider,
///      then debounced (300ms) API search via MarketsListDataProvider
///   3. On "Search/Enter" key: bypass debounce, fire API request immediately
///   4. Handle race conditions: ignore stale API responses if a newer request was sent
///   5. Aggregate results into screenState for the View to render
///   6. On result tap: save query to hints (TokenSearchStorage.saveHint),
///      save market asset to recents (TokenSearchStorage.saveRecent)
///   7. On clear/cancel: reset to .idle, show hints + recents
///   8. On init (screen open): load hints + recents from TokenSearchStorage in parallel (BF-01)
///      If load takes > 100ms, don't block UI — render empty, update when ready
///
/// isSearching ownership:
///   TokenSearchViewModel publishes its own isSearching state.
///   MarketsMainViewModel reads it to drive showSearchResult in the View.
///   When redesign is ON, MarketsMainViewModel should NOT run its own searchTextBind() —
///   TokenSearchViewModel fully owns the search subscription to avoid duplicate API calls.
///
/// Dependencies (injected):
///   - headerViewModel: MainBottomSheetHeaderViewModel (search input events)
///   - storage: TokenSearchStorage (hints + recents persistence)
///   - userAssetsProvider: UserAssetsSearchProvider (local portfolio filtering)
///   - marketsDataProvider: MarketsListDataProvider (existing API search, reuse as-is)
///
/// Key constraint: search text must NEVER be logged to analytics or console (privacy, see NFR spec)
final class TokenSearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var screenState: TokenSearchScreenState = .idle
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var result: TokenSearchResult?

    // MARK: - Dependencies

    let headerViewModel: MainBottomSheetHeaderViewModel
    let storage: any TokenSearchStorage
    let userAssetsProvider: any UserAssetsSearchProviding

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        headerViewModel: MainBottomSheetHeaderViewModel,
        storage: some TokenSearchStorage = StubTokenSearchStorage(),
        userAssetsProvider: some UserAssetsSearchProviding = StubUserAssetsSearchProvider()
    ) {
        self.headerViewModel = headerViewModel
        self.storage = storage
        self.userAssetsProvider = userAssetsProvider

        bind()
    }

    // MARK: - Actions

    func onResultTapped(query: String, marketAssetId: String?) {
        // [STUB] Delete this body when implemented.
        // 1. Save query to hints: storage.saveHint(query)
        // 2. If marketAssetId != nil: storage.saveRecent(assetId: marketAssetId)
        // 3. Navigate to Token Details or Market Token Details (via coordinator)
    }

    func onClearAllHistory() {
        // [STUB] Delete this body when implemented.
        storage.clearAll()
    }

    func onShowMoreUserAssets() {
        // [STUB] Delete this body when implemented.
        // Rebuild resultSections with isUserAssetsCollapsed = false
    }

    func onRetryMarketSearch() {
        // [STUB] Delete this body when implemented.
        // Re-fire the last API request for market assets
    }

    // MARK: - Private

    private func bind() {
        // [STUB] Delete this body when implemented.
        // Subscribe to headerViewModel.enteredSearchInputPublisher:
        //   .textInput(value) → run local search instantly, debounce(300ms) API search
        //   .clearInput / .cancelInput → reset to .idle, reload hints + recents
        //
        // Race condition handling:
        //   Use switchToLatest or request ID tracking to ignore stale API responses
    }
}
