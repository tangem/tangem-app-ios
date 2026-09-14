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
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

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
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var addFundsState: AddFundsState = .loading
    @Published private(set) var positionsState: PositionsState = .loading
    @Published private(set) var isSearching = false
    @Published var isSearchFieldActive = false
    @Published var searchQuery = ""
    @Published var alert: AlertBinder?

    let search: PolymarketSearchViewModel

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var selectedCategoryTab: Binding<PolymarketCategoryTab> {
        Binding(
            get: { self.categoryTabs.first { $0.id == self.selectedCategoryID } ?? self.categoryTabs.first ?? PolymarketCategoryTab(id: 0, title: "") },
            set: { self.select(categoryID: $0.id) }
        )
    }

    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let balanceProvider: PolymarketBalanceProvider
    private let accountFundsInteractor: PolymarketAccountFundsInteractor?
    private let positionsService: PolymarketPositionsService?
    private weak var coordinator: PolymarketMainRoutable?

    private let balanceStateBuilder = LoadableBalanceViewStateBuilder()

    private var balanceSubscription: AnyCancellable?
    private var balanceRefreshTask: Task<Void, Never>?
    private var accountFundsPreparationTask: Task<Void, Never>?
    private var awaitingFundsTask: Task<Void, Never>?
    private var searchBag: Set<AnyCancellable> = []
    private var bag: Set<AnyCancellable> = []

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?
    private var positionsTask: Task<Void, Never>?

    init(
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        balanceProvider: PolymarketBalanceProvider,
        accountFundsInteractor: PolymarketAccountFundsInteractor?,
        positionsService: PolymarketPositionsService?,
        coordinator: PolymarketMainRoutable
    ) {
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        search = PolymarketSearchViewModel(apiProvider: apiProvider)
        self.balanceProvider = balanceProvider
        self.accountFundsInteractor = accountFundsInteractor
        self.positionsService = positionsService
        self.coordinator = coordinator
        search.coordinator = self

        bindSearch()
        bindBalance()
        bindGeoblockState()
        startBalanceRefresh()
        load()
        loadPositions()
    }

    deinit {
        balanceRefreshTask?.cancel()
        accountFundsPreparationTask?.cancel()
        awaitingFundsTask?.cancel()
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

    private func bindGeoblockState() {
        geoblockStateProvider
            .statePublisher
            .map { $0 == .blocked }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isRestricted in
                viewModel.isRegionRestricted = isRestricted
            }
            .store(in: &bag)
    }

    private func startBalanceRefresh() {
        balanceRefreshTask = Task { @MainActor [weak self] in
            await self?.balanceProvider.refresh()

            while !Task.isCancelled {
                let interval = self?.isAwaitingFunds == true
                    ? Constants.awaitingFundsBalanceRefreshInterval
                    : Constants.balanceRefreshInterval

                try? await Task.sleep(for: .seconds(interval))

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

    private func prepareAccountFunds() {
        guard accountFundsInteractor != nil else {
            addFundsState = .unavailable
            return
        }

        accountFundsPreparationTask?.cancel()

        if addFundsState != .available {
            addFundsState = .loading
        }

        accountFundsPreparationTask = runTask(in: self) { @MainActor viewModel in
            guard let interactor = viewModel.accountFundsInteractor else { return }

            let state = await interactor.prepare()

            guard !Task.isCancelled else { return }

            viewModel.addFundsState = AddFundsState(state)
        }
    }

    // MARK: - Positions

    func loadPositions() {
        guard let positionsService else {
            positionsState = .loaded([])
            return
        }

        positionsTask?.cancel()

        if case .loaded = positionsState {} else {
            positionsState = .loading
        }

        positionsTask = runTask(in: self) { @MainActor viewModel in
            do {
                let positions = try await positionsService.activePositions(limit: Constants.positionsLimit)
                try Task.checkCancellation()

                viewModel.positionsState = .loaded(
                    positions.prefix(Constants.positionsShown).map(PolymarketPositionRow.Model.make(position:))
                )
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the open positions", error: error)
                viewModel.positionsState = .failed
            }
        }
    }

    // MARK: - Actions

    func load() {
        loadingTask?.cancel()

        cache = [:]
        resetEvents()
        loadingState = .loading

        prepareAccountFunds()

        loadingTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadCategories()
        }
    }

    func retry() {
        guard !categories.isEmpty else {
            load()
            return
        }

        fetchEvents()
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

    @MainActor
    func openHowItWorks() {
        coordinator?.openHowItWorks()
    }

    func startAwaitingFunds() {
        awaitingFundsTask?.cancel()
        isAwaitingFunds = true

        balanceRefreshTask?.cancel()
        startBalanceRefresh()

        awaitingFundsTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.awaitingFundsDuration))

            guard !Task.isCancelled else { return }

            self?.isAwaitingFunds = false
        }
    }

    func onAddFundsTap() {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        switch addFundsState {
        case .available:
            coordinator?.openAddFunds()
        case .loading:
            break
        case .unavailable:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
        }
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

            let page = try await apiProvider.events(request: .init(category: firstCategoryID, limit: Constants.pageSize, cursor: nil))
            try Task.checkCancellation()

            self.categories = categories
            selectedCategoryID = firstCategoryID
            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    @MainActor
    private func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await apiProvider.events(request: .init(category: categoryID, limit: Constants.pageSize, cursor: nil))
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
                let page = try await viewModel.apiProvider.events(
                    request: .init(category: categoryID, limit: Constants.pageSize, cursor: requestCursor)
                )
                try Task.checkCancellation()

                viewModel.apply(page: page)
            } catch {
                viewModel.handleFetchFailure(error)
            }
        }
    }

    private func apply(page: PolymarketEventsPage) {
        let added = append(events: page.events)

        cursor = page.cursor
        hasNext = page.hasNext

        guard added > 0 || !page.hasNext else {
            fetchEvents(more: true)
            return
        }

        loadingState = events.isEmpty ? .noResults : (page.hasNext ? .loaded : .allDataLoaded)
    }

    private func handleFetchFailure(_ error: Error) {
        guard !error.isCancellationError else { return }

        if !events.isEmpty, Self.isStaleCursorFailure(error) {
            cursor = nil
        }

        loadingState = events.isEmpty ? .error : .paginationError
    }

    private static func isStaleCursorFailure(_ error: Error) -> Bool {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError else { return false }

        return statusCode == Constants.staleCursorStatusCode
    }

    @discardableResult
    private func append(events newEvents: [PolymarketEvent]) -> Int {
        var known = Set(events.map(\.id))
        let fresh = newEvents.filter { known.insert($0.id).inserted }

        events.append(contentsOf: fresh)
        eventCards.append(contentsOf: fresh.map(makeCard))

        return fresh.count
    }

    private var selectedCategory: PolymarketCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private func makeCard(for event: PolymarketEvent) -> PolymarketEventCard.Model {
        .make(
            event: event,
            category: nil,
            isInActivePredicts: false,
            onSelectOutcome: { [weak self] _, _ in
                self?.openEventDetails(eventID: event.id)
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

    func steady(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .loading(.cache(let cached)) = formatted else { return formatted }

        return .loaded(cached.balance)
    }
}

extension PolymarketMainViewModel {
    enum PositionsState: Equatable {
        case loading
        case loaded([PolymarketPositionRow.Model])
        case failed
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
        static let pageSize = 20
        static let staleCursorStatusCode = 502

        static let balanceRefreshInterval: TimeInterval = 30
        static let awaitingFundsDuration: TimeInterval = 30
        static let awaitingFundsBalanceRefreshInterval: TimeInterval = 5
        static let positionsLimit = 10
        static let positionsShown = 3
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refresh() async {
        prepareAccountFunds()
        geoblockStateProvider.refresh()
        loadingTask?.cancel()

        await balanceProvider.refresh()
        loadPositions()

        if categories.isEmpty {
            await loadCategories()
        } else {
            await reloadSelectedCategory()
        }
    }
}

// MARK: - Add funds

extension PolymarketMainViewModel {
    enum AddFundsState: Equatable {
        case loading
        case available
        case unavailable

        init(_ state: PolymarketAccountFundsInteractor.State) {
            switch state {
            case .loading: self = .loading
            case .ready(let readiness): self = readiness.depositTarget == nil ? .unavailable : .available
            case .unavailable: self = .unavailable
            }
        }
    }
}

// MARK: - PolymarketSearchRoutable protocol conformance

extension PolymarketMainViewModel: PolymarketSearchRoutable {
    func openEventDetailsFromSearch(eventID: String) {
        coordinator?.openEventDetails(eventID: eventID, category: nil)
    }
}
