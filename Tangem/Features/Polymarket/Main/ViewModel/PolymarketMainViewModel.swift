//
//  PolymarketMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemPolymarket

final class PolymarketMainViewModel: ObservableObject {
    @Published private(set) var categories: [PolymarketCategory] = [] {
        didSet { categoryTabs = categories.map { PolymarketCategoryTab(id: $0.id, title: $0.label) } }
    }

    @Published private(set) var eventCards: [PolymarketEventCard.Model] = []
    @Published private(set) var selectedCategoryID: Int?
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var isTabsPinned = false

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var selectedCategoryTab: Binding<PolymarketCategoryTab> {
        Binding(
            get: { self.categoryTabs.first { $0.id == self.selectedCategoryID } ?? self.categoryTabs.first ?? PolymarketCategoryTab(id: 0, title: "") },
            set: { self.select(categoryID: $0.id) }
        )
    }

    private let apiProvider: PolymarketAPIProvider
    private weak var coordinator: PolymarketMainRoutable?

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?

    init(apiProvider: PolymarketAPIProvider, coordinator: PolymarketMainRoutable) {
        self.apiProvider = apiProvider
        self.coordinator = coordinator

        load()
    }

    // MARK: - Actions

    func load() {
        loadingTask?.cancel()

        cache = [:]
        resetEvents()
        loadingState = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let categories = try await viewModel.apiProvider.categories(locale: viewModel.locale)
                try Task.checkCancellation()

                // Without categories there is no feed to show, so this is an error rather than an empty state
                guard let firstCategoryID = categories.first?.id else {
                    viewModel.loadingState = .error
                    return
                }

                let page = try await viewModel.apiProvider.events(request: .init(category: firstCategoryID, cursor: nil))
                try Task.checkCancellation()

                viewModel.categories = categories
                viewModel.selectedCategoryID = firstCategoryID
                viewModel.apply(page: page)
            } catch {
                viewModel.handleFetchFailure(error)
            }
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
        fetchEvents(more: true)
    }

    func dismiss() {
        coordinator?.dismiss()
    }

    func updatePinnedState(tabsMinY: CGFloat, navBarHeight: CGFloat) {
        let pinned = tabsMinY <= navBarHeight
        if pinned != isTabsPinned {
            isTabsPinned = pinned
        }
    }

    // MARK: - Private

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

    private func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })
    }

    private func resetEvents() {
        events = []
        eventCards = []
        cursor = nil
        hasNext = false
    }

    /// The cache keeps data only: a restored category has no request behind it, so a transient
    /// `.paginationLoading` or `.paginationError` must not come back with it.
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
}
