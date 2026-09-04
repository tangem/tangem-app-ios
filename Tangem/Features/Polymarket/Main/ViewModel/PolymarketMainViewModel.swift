//
//  PolymarketMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets
import TangemFoundation
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

final class PolymarketMainViewModel: ObservableObject {
    @Published private(set) var categories: [PolymarketCategory] = [] {
        didSet { categoryTabs = categories.map { PolymarketCategoryTab(id: $0.id, title: $0.label) } }
    }

    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var selectedCategoryID: Int?
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var isTabsPinned = false
    @Published private(set) var balance: LoadableBalanceView.State = .loading(cached: .none)
    @Published private(set) var isRegionRestricted = false
    @Published private(set) var isSearching = false
    @Published var isSearchFieldActive = false
    @Published var searchQuery = ""

    let search: PolymarketSearchViewModel

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var selectedCategoryTab: Binding<PolymarketCategoryTab> {
        Binding(
            get: { self.categoryTabs.first { $0.id == self.selectedCategoryID } ?? self.categoryTabs.first ?? PolymarketCategoryTab(id: 0, title: "") },
            set: { self.select(categoryID: $0.id) }
        )
    }

    private let apiProvider: PolymarketAPIProvider
    private let geoblockService: PolymarketGeoblockService
    private let balanceProvider: PolymarketBalanceProvider
    private weak var coordinator: PolymarketMainRoutable?

    private let balanceStateBuilder = LoadableBalanceViewStateBuilder()

    private var balanceSubscription: AnyCancellable?
    private var balanceRefreshTask: Task<Void, Never>?
    private var searchBag: Set<AnyCancellable> = []

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?

    init(
        apiProvider: PolymarketAPIProvider,
        geoblockService: PolymarketGeoblockService,
        balanceProvider: PolymarketBalanceProvider,
        coordinator: PolymarketMainRoutable
    ) {
        self.apiProvider = apiProvider
        self.geoblockService = geoblockService
        search = PolymarketSearchViewModel(apiProvider: apiProvider)
        self.balanceProvider = balanceProvider
        self.coordinator = coordinator
        search.coordinator = self

        bindSearch()
        bindBalance()
        startBalanceRefresh()
        load()
        loadRegion()
    }

    deinit {
        balanceRefreshTask?.cancel()
    }

    private func bindSearch() {
        $searchQuery
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, query in viewModel.search.query = query }
            .store(in: &searchBag)

        $isSearchFieldActive
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.isSearching = true }
            .store(in: &searchBag)
    }

    private func loadRegion() {
        runTask(in: self) { @MainActor viewModel in
            do {
                viewModel.isRegionRestricted = try await viewModel.geoblockService.geoblock().isBlocked
            } catch {
                PolymarketLogger.error("Failed to read the region, treating it as blocked", error: error)
                viewModel.isRegionRestricted = true
            }
        }
    }

    private func startBalanceRefresh() {
        balanceRefreshTask = Task { @MainActor [weak self] in
            await self?.balanceProvider.refresh()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.balanceRefreshInterval))

                guard !Task.isCancelled, let self else { return }

                await balanceProvider.refresh()
            }
        }
    }

    private func bindBalance() {
        balanceSubscription = balanceProvider
            .balancePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, formatted in
                viewModel.balance = viewModel.makeBalanceState(from: formatted)
            }
    }

    // MARK: - Actions

    func load() {
        loadingTask?.cancel()

        cache = [:]
        resetEvents()
        loadingState = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadCategories()
        }
    }

    func select(categoryID: Int?) {
        guard selectedCategoryID != categoryID else { return }

        loadingTask?.cancel()
        cache[selectedCategoryID] = snapshot()
        selectedCategoryID = categoryID

        if let cached = cache[categoryID], !cached.events.isEmpty {
            restore(cached)
        } else {
            fetchEvents()
        }
    }

    func loadMore() {
        guard hasNext, loadingState != .paginationLoading else { return }

        fetchEvents(more: true)
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    func onAddFundsTap() {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        // [REDACTED_TODO_COMMENT]
    }

    func exitSearch() {
        isSearching = false
        isSearchFieldActive = false
        searchQuery = ""
        search.reset()
    }

    func openEventDetails(eventID: String) {
        coordinator?.openEventDetails(eventID: eventID, category: selectedCategory)
    }

    func updatePinnedState(tabsMinY: CGFloat, navBarHeight: CGFloat) {
        let pinned = tabsMinY <= navBarHeight
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }

    // MARK: - Private

    @MainActor
    private func loadCategories() async {
        do {
            let categories = try await apiProvider.categories(locale: locale)
            try Task.checkCancellation()

            guard let firstCategoryID = categories.first?.id else {
                loadingState = .error
                return
            }

            let page = try await apiProvider.events(request: .init(category: firstCategoryID, cursor: nil))
            try Task.checkCancellation()

            self.categories = categories
            selectedCategoryID = firstCategoryID
            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    /// Refetches the open tab in place: the visible list stays put until the new page arrives, and the tab keeps its place.
    @MainActor
    private func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await apiProvider.events(request: .init(category: categoryID, cursor: nil))
            try Task.checkCancellation()

            guard categoryID == selectedCategoryID else { return }

            cache[categoryID] = nil
            resetEvents()
            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    private func fetchEvents(more: Bool = false) {
        loadingTask?.cancel()

        if !more {
            resetEvents()
        }

        loadingState = events.isEmpty ? .loading : .paginationLoading

        let categoryID = selectedCategoryID
        let requestCursor = more ? cursor : nil

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.apiProvider.events(request: .init(category: categoryID, cursor: requestCursor))
                try Task.checkCancellation()

                viewModel.apply(page: page)
            } catch {
                viewModel.handleFetchFailure(error)
            }
        }
    }

    private func apply(page: PolymarketEventsPage) {
        append(events: page.events)
        cursor = page.cursor
        hasNext = page.hasNext

        loadingState = events.isEmpty ? .noResults : (page.hasNext ? .loaded : .allDataLoaded)
    }

    private func handleFetchFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        loadingState = events.isEmpty ? .error : .paginationError
    }

    private func append(events newEvents: [PolymarketEvent]) {
        events.append(contentsOf: newEvents)
        eventCards.append(contentsOf: newEvents.map(makeCard))
    }

    private var selectedCategory: PolymarketCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(
            event: event,
            category: nil,
            isInActivePredicts: false,
            onSelectOutcome: { [weak self] market, outcome in
                self?.coordinator?.openOrder(market: market, outcome: outcome)
            }
        )
    }

    private func resetEvents() {
        events = []
        eventCards = []
        cursor = nil
        hasNext = false
    }

    private func snapshot() -> CategoryState {
        CategoryState(events: events, cursor: cursor, hasNext: hasNext)
    }

    private func restore(_ state: CategoryState) {
        resetEvents()
        append(events: state.events)
        cursor = state.cursor
        hasNext = state.hasNext
        loadingState = state.hasNext ? .loaded : .allDataLoaded
    }

    private var locale: String? {
        Locale.current.language.languageCode?.identifier
    }
}

private extension PolymarketMainViewModel {
    func makeBalanceState(from formatted: FormattedTokenBalanceType) -> LoadableBalanceView.State {
        AttributedBalanceFormatter.decimalColored(
            balanceStateBuilder.build(type: steady(formatted)),
            integerPart: .init(
                font: TangemFontStyle(DesignSystem.Font.displayMediumToken),
                color: DesignSystem.Color.textPrimary
            ),
            fractionalPart: .init(
                font: TangemFontStyle(DesignSystem.Font.headingMediumToken),
                color: DesignSystem.Color.textPrimary
            )
        )
    }

    /// The balance is polled in the background, and a cached value being refreshed is still the number to show.
    func steady(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .loading(.cache(let cached)) = formatted else { return formatted }

        return .loaded(cached.balance)
    }
}

extension PolymarketMainViewModel {
    enum LoadingState: Equatable {
        case loading
        case error
        case noResults
        case loaded
        case allDataLoaded
        case paginationLoading
        case paginationError
    }
}

private extension PolymarketMainViewModel {
    struct CategoryState {
        let events: [PolymarketEvent]
        let cursor: String?
        let hasNext: Bool
    }

    enum Constants {
        static let balanceRefreshInterval: TimeInterval = 30
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        loadRegion()
        loadingTask?.cancel()

        await balanceProvider.refresh()

        if categories.isEmpty {
            await loadCategories()
        } else {
            await reloadSelectedCategory()
        }
    }
}

// MARK: - PolymarketSearchRoutable protocol conformance

extension PolymarketMainViewModel: PolymarketSearchRoutable {
    func openEventDetailsFromSearch(eventID: String) {
        coordinator?.openEventDetails(eventID: eventID, category: nil)
    }
}
