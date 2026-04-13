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
///
/// Key constraint: search text must NEVER be logged to analytics or console (privacy, see NFR spec)
final class TokenSearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var screenState: TokenSearchScreenState = .empty
    @Published private(set) var isSearching: Bool = false

    // MARK: - Dependencies

    let headerViewModel: MainBottomSheetHeaderViewModel

    private let storage: any TokenSearchStorage
    private let userAssetsProvider: any UserAssetsSearchProviding
    private let chartsHistoryProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider
    private let marketCapFormatter: MarketCapFormatter
    private weak var coordinator: MarketsRoutable?

    // MARK: - Private

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        headerViewModel: MainBottomSheetHeaderViewModel,
        storage: some TokenSearchStorage = StubTokenSearchStorage(),
        userAssetsProvider: some UserAssetsSearchProviding = StubUserAssetsSearchProvider(),
        chartsHistoryProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider,
        coordinator: MarketsRoutable? = nil
    ) {
        self.headerViewModel = headerViewModel
        self.storage = storage
        self.userAssetsProvider = userAssetsProvider
        self.chartsHistoryProvider = chartsHistoryProvider
        self.filterProvider = filterProvider
        self.coordinator = coordinator

        marketCapFormatter = MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        bind()
    }

    // MARK: - Actions

    /// User tapped a query hint in the Recents block.
    /// Fills the search field with the query text and triggers search (BF-09).
    func onQueryHintTapped(_ query: String) {
        headerViewModel.enteredSearchText = query
    }

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

    private enum Activity: Equatable {
        case inactive
        case idle
        case typing(String)
    }

    private func bind() {
        let screenStatePublisher = Publishers.CombineLatest(
            makeActivityPublisher(),
            makeIdleContentPublisher()
        )
        .map(resolveScreenState(activity:idleContent:))
        .share(replay: 1)

        screenStatePublisher
            .map { $0 != nil }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isSearching)

        screenStatePublisher
            .compactMap { $0 }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$screenState)
    }

    private func resolveScreenState(
        activity: Activity,
        idleContent: TokenSearchScreenState.IdleContent?
    ) -> TokenSearchScreenState? {
        switch activity {
        case .inactive:
            return nil

        case .idle:
            return idleContent.map(TokenSearchScreenState.idle)

        case .typing:
            return .searching
        }
    }

    private func makeIdleContent(from items: [TokenSearchRecentItem]) -> TokenSearchScreenState.IdleContent? {
        var queries: [String] = []
        var marketAssetViewModels: [MarketTokenItemViewModel] = []

        for item in items {
            switch item {
            case .query(let text):
                queries.append(text)

            case .marketAsset(let tokenModel):
                marketAssetViewModels.append(makeMarketTokenItemViewModel(for: tokenModel))
            }
        }

        guard queries.isNotEmpty || marketAssetViewModels.isNotEmpty else { return nil }

        return TokenSearchScreenState.IdleContent(
            queries: queries,
            marketAssetViewModels: marketAssetViewModels
        )
    }

    private func makeMarketTokenItemViewModel(for tokenModel: MarketsTokenModel) -> MarketTokenItemViewModel {
        MarketTokenItemViewModel(
            tokenModel: tokenModel,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.onMarketAssetTapped(tokenModel: tokenModel)
            }
        )
    }

    private func makeActivityPublisher() -> AnyPublisher<Activity, Never> {
        let inputActivity = headerViewModel.enteredSearchInputPublisher
            .dropFirst()
            .map { input -> Activity in
                switch input {
                case .textInput(let value):
                    return value.isEmpty ? .idle : .typing(value)

                case .clearInput, .cancelInput:
                    return .inactive
                }
            }

        // On focus gain: derive activity from current text — don't blindly force .idle
        // (re-focusing while text exists should keep .typing).
        let focusActivity = headerViewModel.$inputShouldBecomeFocused
            .filter { $0 }
            .withWeakCaptureOf(self)
            .map { viewModel, _ -> Activity in
                let text = viewModel.headerViewModel.enteredSearchText
                return text.isEmpty ? .idle : .typing(text)
            }

        return Publishers.Merge(inputActivity, focusActivity)
            .prepend(.inactive)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func makeIdleContentPublisher() -> AnyPublisher<TokenSearchScreenState.IdleContent?, Never> {
        storage.recentItemsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, items in viewModel.makeIdleContent(from: items) }
            .eraseToAnyPublisher()
    }
}
