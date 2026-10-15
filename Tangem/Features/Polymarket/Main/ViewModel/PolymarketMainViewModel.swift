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
    @Published private(set) var balanceMode: BalanceMode = .available
    @Published private(set) var canSwitchBalanceMode = false
    @Published private(set) var isRegionRestricted = false
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var addFundsState: ActionState = .loading
    @Published private(set) var withdrawState: WithdrawState = .loading
    @Published private(set) var positionsState: PositionsState = .loading
    @Published private(set) var hasFinishedPositions = false
    @Published private(set) var hasMorePositions = false
    @Published private(set) var isSearching = false
    @Published var isSearchFieldActive = false
    @Published var searchQuery = ""
    @Published var alert: AlertBinder?

    let search: PolymarketSearchViewModel

    private(set) var categoryTabs: [PolymarketCategoryTab] = []

    var showsPositions: Bool {
        switch positionsState {
        case .loading: false
        case .failed: true
        case .loaded(let models): !models.isEmpty || hasFinishedPositions || hasMorePositions
        }
    }

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
    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private weak var coordinator: PolymarketMainRoutable?

    private static let balanceFormatter = BalanceFormatter()

    private let balanceStateBuilder = LoadableBalanceViewStateBuilder()

    private var accountFundsReadiness: PolymarketAccountFundsInteractor.State = .loading
    private var collateralBalance: TokenBalanceType = .loading(.none)

    private var balanceSubscription: AnyCancellable?
    private var cachedBalance: FormattedTokenBalanceType.Cached?
    private var availableBalance: FormattedTokenBalanceType?
    private var totalBalance: FormattedTokenBalanceType?
    private var balanceRefreshTask: Task<Void, Never>?
    private var accountFundsPreparationTask: Task<Void, Never>?
    private var searchBag: Set<AnyCancellable> = []
    private var bag: Set<AnyCancellable> = []

    private var events: [PolymarketEvent] = []
    private var cursor: String?
    private var hasNext = false
    private var cache: [Int?: CategoryState] = [:]
    private var loadingTask: Task<Void, Never>?
    private var positionsTask: Task<Void, Never>?
    private var contentRefreshTask: Task<Void, Never>?
    private var orderTask: Task<Void, Never>?
    private var claimTask: Task<Void, Never>?
    private var openPositions: [PolymarketPosition] = []

    init(
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        balanceProvider: PolymarketBalanceProvider,
        accountFundsInteractor: PolymarketAccountFundsInteractor?,
        positionsService: PolymarketPositionsService?,
        fundsArrivalTracker: PolymarketFundsArrivalTracker,
        coordinator: PolymarketMainRoutable
    ) {
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        search = PolymarketSearchViewModel(apiProvider: apiProvider)
        self.balanceProvider = balanceProvider
        self.accountFundsInteractor = accountFundsInteractor
        self.positionsService = positionsService
        self.fundsArrivalTracker = fundsArrivalTracker
        self.coordinator = coordinator
        search.coordinator = self

        bindSearch()
        bindBalance()
        bindGeoblockState()
        bindApplicationState()
        bindFundsArrival()
        startBalanceRefresh()
        startContentRefresh()
        load()
        loadPositions()
    }

    deinit {
        orderTask?.cancel()
        claimTask?.cancel()
        balanceRefreshTask?.cancel()
        accountFundsPreparationTask?.cancel()
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

    private func bindFundsArrival() {
        fundsArrivalTracker
            .$isAwaitingFunds
            .receiveOnMain()
            .assign(to: &$isAwaitingFunds)

        fundsArrivalTracker
            .$isBalanceChangeExpected
            .removeDuplicates()
            .filter { $0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.balanceRefreshTask?.cancel()
                viewModel.startBalanceRefresh()
            }
            .store(in: &bag)
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

                if isRestricted {
                    viewModel.coordinator?.openRegionWarning()
                }
            }
            .store(in: &bag)
    }

    private func bindApplicationState() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.stopBalanceRefresh()
                viewModel.stopContentRefresh()
            }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.startBalanceRefresh()
                viewModel.startContentRefresh()
            }
            .store(in: &bag)
    }

    private func stopContentRefresh() {
        contentRefreshTask?.cancel()
        contentRefreshTask = nil
    }

    private func startContentRefresh() {
        contentRefreshTask?.cancel()

        contentRefreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.contentRefreshInterval))

                guard !Task.isCancelled, let self else { return }

                loadPositions()
                await refreshVisibleEvents()
            }
        }
    }

    private func stopBalanceRefresh() {
        balanceRefreshTask?.cancel()
        balanceRefreshTask = nil
    }

    private func startBalanceRefresh() {
        balanceRefreshTask?.cancel()

        balanceRefreshTask = Task { @MainActor [weak self] in
            await self?.balanceProvider.refresh(scope: .full)

            while !Task.isCancelled {
                let interval = self?.fundsArrivalTracker.isBalanceChangeExpected == true
                    ? Constants.expectedChangeBalanceRefreshInterval
                    : Constants.balanceRefreshInterval

                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled, let self else { return }

                let scope: PolymarketBalanceRefreshScope = fundsArrivalTracker.isBalanceChangeExpected ? .availableOnly : .full

                await balanceProvider.refresh(scope: scope)
            }
        }
    }

    private func bindBalance() {
        balanceSubscription = balanceProvider
            .balancePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, formatted in
                viewModel.recordBalance(formatted)
                viewModel.availableBalance = formatted
                viewModel.updateBalance()
            }

        balanceProvider
            .totalBalancePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, formatted in
                viewModel.totalBalance = formatted
                viewModel.updateBalance()
            }
            .store(in: &bag)

        balanceProvider
            .collateralBalancePublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, balance in
                viewModel.collateralBalance = balance
                viewModel.refreshActionStates()
            }
            .store(in: &bag)
    }

    private func prepareAccountFunds() {
        guard accountFundsInteractor != nil else {
            apply(.unavailable)
            return
        }

        accountFundsPreparationTask?.cancel()

        accountFundsPreparationTask = runTask(in: self) { @MainActor viewModel in
            guard let interactor = viewModel.accountFundsInteractor else { return }

            let state = await interactor.prepare()

            guard !Task.isCancelled else { return }

            viewModel.apply(state)
        }
    }

    private func apply(_ readiness: PolymarketAccountFundsInteractor.State) {
        accountFundsReadiness = readiness
        refreshActionStates()
    }

    private func refreshActionStates() {
        switch accountFundsReadiness {
        case .loading:
            addFundsState = .loading
            withdrawState = .loading

        case .ready(let readiness):
            addFundsState = readiness.depositTargets.isEmpty ? .unavailable : .available
            withdrawState = withdrawStateForPreparedAccount(readiness)

        case .unavailable:
            addFundsState = .unavailable
            withdrawState = .unavailable(.accountUnavailable)
        }
    }

    private func withdrawStateForPreparedAccount(_ readiness: PolymarketAccountFundsInteractor.Readiness) -> WithdrawState {
        let minimum = PolymarketUSDAmount(usd: readiness.collateralMinCheckoutUSD).inToken()

        switch collateralBalance {
        case .loaded(let balance):
            return withdrawState(forBalance: balance, minimum: minimum)
        case .loading(.some(let cached)), .failure(.some(let cached)):
            return withdrawState(forBalance: cached.balance, minimum: minimum)
        case .loading:
            return .loading
        case .empty, .failure:
            return .unavailable(.balanceUnavailable)
        }
    }

    private func withdrawState(forBalance balance: Decimal, minimum: Decimal?) -> WithdrawState {
        guard balance > 0 else {
            return .unavailable(.emptyBalance)
        }

        guard let minimum, balance < minimum else {
            return .available
        }

        let formatted = Self.balanceFormatter.formatCryptoBalance(
            minimum,
            currencyCode: PolymarketUtilities.usdcTokenItem.currencySymbol
        )

        return .unavailable(.tooSmallBalance(minimumFormatted: formatted))
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
                async let finished = Self.probeFinishedPositions(service: positionsService)
                let page = try await Self.activePositions(service: positionsService)
                try Task.checkCancellation()

                viewModel.openPositions = Array(page.positions.prefix(Constants.positionsShown))
                viewModel.hasMorePositions = page.hasNext || page.receivedCount > viewModel.openPositions.count

                let probed = await finished

                try Task.checkCancellation()

                if let probed {
                    viewModel.hasFinishedPositions = probed
                } else if viewModel.openPositions.isEmpty, !viewModel.hasFinishedPositions {
                    viewModel.positionsState = .failed
                    return
                }

                withAnimation(.easeInOut(duration: Constants.listAnimationDuration)) {
                    viewModel.positionsState = .loaded(
                        viewModel.openPositions.map(PolymarketPositionRow.Model.make(position:))
                    )
                }
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to load the open positions", error: error)

                if case .loaded = viewModel.positionsState { return }

                viewModel.positionsState = .failed
            }
        }
    }

    private static func probeFinishedPositions(service: PolymarketPositionsService) async -> Bool? {
        do {
            return try await closedPositionsExist(service: service)
        } catch {
            guard !error.isCancellationError else { return nil }

            PolymarketLogger.error("Failed to probe the closed positions", error: error)
            return nil
        }
    }

    private static func closedPositionsExist(service: PolymarketPositionsService) async throws -> Bool {
        do {
            return try await closedPositionsPage(service: service).receivedCount > 0
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.positionsRetryDelay))

            return try await closedPositionsPage(service: service).receivedCount > 0
        }
    }

    private static func closedPositionsPage(
        service: PolymarketPositionsService
    ) async throws -> PolymarketClosedPositionsPage {
        try await service.closedPositions(
            sort: .closedAt,
            ascending: false,
            limit: Constants.finishedProbeLimit,
            offset: 0
        )
    }

    private func events(category: Int?, cursor: String?) async throws -> PolymarketEventsPage {
        let request = PolymarketEventsRequest(category: category, limit: Constants.pageSize, cursor: cursor)

        do {
            return try await apiProvider.events(request: request)
        } catch {
            guard !error.isCancellationError else { throw error }

            try await Task.sleep(for: .seconds(Constants.silentRetryDelay))

            return try await apiProvider.events(request: request)
        }
    }

    private static func activePositions(service: PolymarketPositionsService) async throws -> PolymarketPositionsPage {
        do {
            return try await service.activePositions(limit: Constants.positionsLimit)
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.positionsRetryDelay))

            return try await service.activePositions(limit: Constants.positionsLimit)
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

    @MainActor
    func openMyPositions(tab: PolymarketPositionsTab) {
        coordinator?.openMyPositions(
            tab: tab,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) },
            onClaimed: { [weak self] in self?.claimed() }
        )
    }

    func onBalanceModeTap() {
        guard canSwitchBalanceMode else { return }

        balanceMode = balanceMode == .total ? .available : .total
        updateBalance()
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
            alert = AlertBuilder.makeOkGotItAlert(
                message: Localization.predictionAddFundsErrorDescription,
                okAction: { [weak self] in self?.prepareAccountFunds() }
            )
        }
    }

    func onWithdrawTap() {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        switch withdrawState {
        case .available:
            coordinator?.openWithdraw()
        case .loading:
            break
        case .unavailable(let reason):
            alert = AlertBuilder.makeOkGotItAlert(
                message: message(for: reason),
                okAction: { [weak self] in self?.retryWithdrawAvailability(after: reason) }
            )
        }
    }

    private func retryWithdrawAvailability(after reason: WithdrawUnavailability) {
        switch reason {
        case .emptyBalance, .tooSmallBalance:
            break
        case .balanceUnavailable:
            runTask(in: self) { @MainActor viewModel in
                await viewModel.refreshBalance()
            }
        case .accountUnavailable:
            prepareAccountFunds()
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func message(for reason: WithdrawUnavailability) -> String {
        switch reason {
        case .emptyBalance:
            Localization.tokenButtonUnavailabilityReasonEmptyBalanceSend
        case .tooSmallBalance(let minimumFormatted):
            Localization.transferMinAmountError(minimumFormatted)
        case .balanceUnavailable:
            "Couldn't read your Polymarket balance. Refresh or re-enter this screen."
        case .accountUnavailable:
            "Couldn't reach your Polymarket account. Refresh or re-enter this screen."
        }
    }

    func exitSearch() {
        isSearching = false
        isSearchFieldActive = false
        searchQuery = ""
        search.reset()
    }

    func openEventDetails(eventID: String) {
        openEventDetails(eventID: eventID, category: selectedCategory)
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

            self.categories = categories
            selectedCategoryID = firstCategoryID

            let page = try await events(category: firstCategoryID, cursor: nil)
            try Task.checkCancellation()

            apply(page: page)
        } catch {
            handleFetchFailure(error)
        }
    }

    @MainActor
    private func refreshVisibleEvents() async {
        guard !events.isEmpty else { return }

        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
            try Task.checkCancellation()

            guard categoryID == selectedCategoryID else { return }

            replaceVisibleEvents(with: page.events)
        } catch {
            guard !error.isCancellationError else { return }

            PolymarketLogger.error("Failed to refresh the events feed", error: error)
        }
    }

    @MainActor
    private func replaceVisibleEvents(with refreshed: [PolymarketEvent]) {
        let byID = Dictionary(refreshed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        events = events.map { byID[$0.id] ?? $0 }
        eventCards = events.map(makeCard)
    }

    @MainActor
    private func reloadSelectedCategory() async {
        let categoryID = selectedCategoryID

        do {
            let page = try await events(category: categoryID, cursor: nil)
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
                let page = try await viewModel.events(category: categoryID, cursor: requestCursor)
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

    private func openEventDetails(eventID: String, category: PolymarketCategory?) {
        coordinator?.openEventDetails(
            eventID: eventID,
            category: category,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
        )
    }

    private func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard !isRegionRestricted else {
            coordinator?.openRegionWarning()
            return
        }

        coordinator?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: .buy,
            onPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
        )
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
                self?.selectOutcome(market: market, outcome: outcome, eventTitle: event.title)
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
    func updateBalance() {
        canSwitchBalanceMode = totalBalance.map(hasValue) ?? false

        if !canSwitchBalanceMode {
            balanceMode = .available
        }

        switch balanceMode {
        case .available:
            guard let availableBalance else { return }

            balance = makeBalanceState(from: withCachedFallback(availableBalance))

        case .total:
            guard let totalBalance else { return }

            balance = makeBalanceState(from: totalBalance)
        }
    }

    func hasValue(_ formatted: FormattedTokenBalanceType) -> Bool {
        switch formatted {
        case .loaded: true
        case .loading(let cached), .failure(let cached): cached.isCache
        }
    }

    func recordBalance(_ formatted: FormattedTokenBalanceType) {
        switch formatted {
        case .loaded(let balance):
            cachedBalance = .init(balance: balance, date: Date())
        case .loading(.cache(let cache)), .failure(.cache(let cache)):
            cachedBalance = cache
        case .loading(.empty), .failure(.empty):
            break
        }
    }

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

    func withCachedFallback(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .failure(.empty) = formatted, let cachedBalance else { return formatted }

        return .failure(.cache(cachedBalance))
    }

    func steady(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .loading(.cache(let cached)) = formatted else { return formatted }

        return .loaded(cached.balance)
    }
}

extension PolymarketMainViewModel {
    enum BalanceMode {
        case available
        case total
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
        static let expectedChangeBalanceRefreshInterval: TimeInterval = 5
        static let contentRefreshInterval: TimeInterval = 20
        static let positionsLimit = 10
        static let positionsShown = 3
        static let positionsRetryDelay: TimeInterval = 1
        static let silentRetryDelay: TimeInterval = 2
        static let finishedProbeLimit = 1
        static let listAnimationDuration: TimeInterval = 0.25
    }
}

// MARK: - Positions

extension PolymarketMainViewModel {
    func openPosition(id: String) {
        guard let position = openPositions.first(where: { $0.id == id }) else { return }

        guard !position.isRedeemable, position.settlement?.isResolved != true else {
            Task { @MainActor [self] in
                coordinator?.openRedeem(position: position, onClaimed: { [weak self] in self?.claimed() })
            }
            return
        }

        coordinator?.openPositionDetails(
            position: position,
            onOrderPlaced: { [weak self] indexing in self?.orderPlaced(awaiting: indexing) }
        )
    }
}

// MARK: - Claims

private extension PolymarketMainViewModel {
    func claimed() {
        claimTask?.cancel()

        claimTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.refreshAccount()
        }
    }
}

// MARK: - Orders

private extension PolymarketMainViewModel {
    func orderPlaced(awaiting indexing: PolymarketOrderIndexing) {
        orderTask?.cancel()

        orderTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.refreshBalance()
            _ = await indexing.value

            guard !Task.isCancelled else { return }

            await viewModel.refreshAccount()
        }
    }
}

// MARK: - Refresh

extension PolymarketMainViewModel {
    @MainActor
    func refreshBalance() async {
        await balanceProvider.refresh(scope: .full)
    }

    @MainActor
    func refreshAccount() async {
        await refreshBalance()
        loadPositions()
    }

    @MainActor
    func refresh() async {
        prepareAccountFunds()
        geoblockStateProvider.refresh()
        loadingTask?.cancel()

        await balanceProvider.refresh(scope: .full)
        loadPositions()

        if categories.isEmpty {
            await loadCategories()
        } else {
            await reloadSelectedCategory()
        }
    }
}

// MARK: - Action states

extension PolymarketMainViewModel {
    enum ActionState: Equatable {
        case loading
        case available
        case unavailable
    }

    enum WithdrawState: Equatable {
        case loading
        case available
        case unavailable(WithdrawUnavailability)

        var isAvailable: Bool { self == .available }
    }

    enum WithdrawUnavailability: Equatable {
        case emptyBalance
        case tooSmallBalance(minimumFormatted: String)
        case balanceUnavailable
        case accountUnavailable
    }
}

// MARK: - PolymarketSearchRoutable protocol conformance

extension PolymarketMainViewModel: PolymarketSearchRoutable {
    func openEventDetailsFromSearch(eventID: String) {
        isSearchFieldActive = false
        openEventDetails(eventID: eventID, category: nil)
    }

    func openOrderFromSearch(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        isSearchFieldActive = false
        selectOutcome(market: market, outcome: outcome, eventTitle: eventTitle)
    }
}
