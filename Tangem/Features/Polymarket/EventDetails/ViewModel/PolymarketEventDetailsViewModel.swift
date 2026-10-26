//
//  PolymarketEventDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

final class PolymarketEventDetailsViewModel: ObservableObject, Identifiable {
    @Published private(set) var state: State = .loading
    @Published private(set) var chart: ChartState = .loading
    @Published private(set) var isDescriptionExpanded = false
    @Published private(set) var isClosedMarketsExpanded = false

    let eventID: String
    let placeholder: PolymarketEventPlaceholder?
    let isChartEnabled: Bool
    let usesPhaseTwoLayout: Bool
    private(set) var legendLineCount: Int
    let isLiveBadgePulsing: Bool

    private let category: PolymarketCategory?
    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let chartServices: ChartServices?
    private let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
    private weak var coordinator: PolymarketEventDetailsRoutable?

    private var loadingTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var historyTask: Task<Void, Never>?
    private var chartSetup: ChartSetup = .unresolved
    private var hasReportedStaleData = false
    private var isVisible = false
    private var isInBackground = false
    private let appStateObserver = AppStateObserver()

    init(
        eventID: String,
        placeholder: PolymarketEventPlaceholder?,
        category: PolymarketCategory?,
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        chartServices: ChartServices?,
        usesPhaseTwoLayout: Bool,
        isLiveBadgePulsing: Bool,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        coordinator: PolymarketEventDetailsRoutable
    ) {
        self.eventID = eventID
        self.placeholder = placeholder
        self.chartServices = chartServices
        isChartEnabled = chartServices != nil
        self.usesPhaseTwoLayout = usesPhaseTwoLayout
        _chart = Published(initialValue: isChartEnabled ? .loading : .unavailable)
        legendLineCount = PolymarketEventPlaceholder.legendLineCount(marketsCount: placeholder?.marketsCount)
        self.isLiveBadgePulsing = isLiveBadgePulsing
        self.category = category
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        self.onOrderPlaced = onOrderPlaced
        self.coordinator = coordinator

        bindApplicationState()
        load()
    }

    deinit {
        loadingTask?.cancel()
        pollingTask?.cancel()
        refreshTask?.cancel()
        historyTask?.cancel()
        chartSetup.cancel()
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            isVisible = true
            updatePolling(refreshingNow: true)
        case .onDisappear:
            isVisible = false
            updatePolling(refreshingNow: false)
        case .close:
            dismiss()
        case .retry:
            load()
        case .toggleClosedMarkets:
            toggleClosedMarkets()
        case .retryChart:
            retryChart()
        case .expandDescription:
            expandDescription()
        }
    }

    // MARK: - Actions

    private func load() {
        loadingTask?.cancel()
        refreshTask?.cancel()
        stopPolling()
        state = .loading
        resetChart()

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let event = try await viewModel.event()
                let content = viewModel.makeContent(from: event)

                viewModel.legendLineCount = PolymarketEventPlaceholder.legendLineCount(marketsCount: event.totalMarketsCount)
                viewModel.state = .content(content)
                viewModel.configureChart(event: event, content: content)
                viewModel.updatePolling(refreshingNow: false)
            } catch {
                guard !error.isCancellationError else { return }

                viewModel.state = .failed(Failure(error: error))
            }
        }
    }

    private func dismiss() {
        coordinator?.dismissEventDetails()
    }

    @MainActor
    func refresh() async {
        await refreshContent()
        retryChart()
    }

    private func retryChart() {
        guard let session = chartSetup.session else {
            retryChartSetup()
            return
        }

        loadHistory(interval: session.selectedInterval)
    }

    private func retryChartSetup() {
        guard case .sportsFailed = chartSetup else { return }

        chart = .loading

        runTask(in: self) { @MainActor viewModel in
            await viewModel.refreshContent()
        }
    }

    private func bindApplicationState() {
        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            self.isInBackground = isInBackground
            updatePolling(refreshingNow: true)
        }
    }

    private func updatePolling(refreshingNow: Bool) {
        guard isVisible, !isInBackground, case .content = state else {
            stopPolling()
            return
        }

        guard pollingTask == nil else { return }

        startPolling(refreshingNow: refreshingNow)
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func expandDescription() {
        isDescriptionExpanded = true
    }

    private func toggleClosedMarkets() {
        isClosedMarketsExpanded.toggle()
    }

    // MARK: - Loading

    private func startPolling(refreshingNow: Bool = false) {
        pollingTask = Task { @MainActor [weak self] in
            if refreshingNow {
                await self?.refreshContent()
            }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Constants.pollInterval)

                guard !Task.isCancelled, let self else { return }

                await refreshContent()
            }
        }
    }

    @MainActor
    private func refreshContent() async {
        refreshTask?.cancel()

        let task = runTask(in: self) { @MainActor viewModel in
            await viewModel.applyLatestEvent()
        }

        refreshTask = task

        await withTaskCancellationHandler(
            operation: { await task.value },
            onCancel: { task.cancel() }
        )
    }

    @MainActor
    private func applyLatestEvent() async {
        do {
            let event = try await event()

            guard !Task.isCancelled else { return }

            let content = makeContent(from: event)

            legendLineCount = PolymarketEventPlaceholder.legendLineCount(marketsCount: event.totalMarketsCount)
            state = .content(content)

            if chartSetup.session == nil {
                configureChart(event: event, content: content)
            } else {
                refreshChart(with: event)
            }

            hasReportedStaleData = false
        } catch {
            guard !error.isCancellationError else { return }

            PolymarketLogger.error("Event \(eventID) refresh failed, keeping the last data", error: error)

            if case .sportsFailed = chartSetup, case .loading = chart {
                chart = .failed
            }

            guard !hasReportedStaleData else { return }

            hasReportedStaleData = true
            presentOutdatedDataToast()
        }
    }

    private func event() async throws -> PolymarketEvent {
        do {
            return try await apiProvider.event(id: eventID)
        } catch {
            guard !error.isCancellationError else { throw error }

            try await Task.sleep(for: .seconds(Constants.silentRetryDelay))

            return try await apiProvider.event(id: eventID)
        }
    }

    @MainActor
    private func presentOutdatedDataToast() {
        Toast(view: WarningToast(text: Localization.predictionMainDataOutdated))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    private func makeContent(from event: PolymarketEvent) -> PolymarketEventDetailsContent {
        .make(event: event, category: category, abbreviatesHugeVolumeChange: usesPhaseTwoLayout) { [weak self] market, outcome in
            self?.selectOutcome(market: market, outcome: outcome, eventTitle: event.title)
        }
    }

    private func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard !geoblockStateProvider.state.isBlocked else {
            coordinator?.openRegionWarning()
            return
        }

        coordinator?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            request: .buy,
            onPlaced: onOrderPlaced
        )
    }

    // MARK: - Chart

    private func resetChart() {
        chartSetup.cancel()
        chartSetup = .unresolved
        historyTask?.cancel()
        historyTask = nil
        chart = isChartEnabled ? .loading : .unavailable
    }

    @MainActor
    private func configureChart(event: PolymarketEvent, content: PolymarketEventDetailsContent) {
        guard let chartServices else { return }

        let chartedMarkets = content.activeMarkets.isEmpty ? content.closedMarkets : content.activeMarkets
        let marketIDs = chartedMarkets.map(\.id)

        guard event.isSportsMatch else {
            applyChartContent(event: event, marketIDs: marketIDs, sports: nil)
            return
        }

        switch chartSetup {
        case .unavailable(let sports):
            applyChartContent(event: event, marketIDs: marketIDs, sports: sports)
            return
        case .resolvingSports, .ready:
            return
        case .unresolved:
            chart = .loading
        case .sportsFailed:
            break
        }

        chartSetup = .resolvingSports(runTask(in: self) { @MainActor viewModel in
            do {
                let sports = try await chartServices.sportsService.sports(eventSlug: event.slug)

                guard !Task.isCancelled else { return }

                viewModel.applyChartContent(event: event, marketIDs: marketIDs, sports: sports)
            } catch {
                guard !error.isCancellationError, !Task.isCancelled else { return }

                PolymarketLogger.error("Failed to load the event sports for the chart", error: error)
                viewModel.chartSetup = .sportsFailed
                viewModel.chart = .failed
            }
        })
    }

    @MainActor
    private func applyChartContent(event: PolymarketEvent, marketIDs: [String], sports: PolymarketEventSports?) {
        guard let content = PolymarketEventChartContent.make(event: event, marketIDs: marketIDs, sports: sports) else {
            chartSetup = .unavailable(sports)
            chart = .unavailable
            return
        }

        chartSetup = .ready(PolymarketEventChartSession(content: content))
        loadHistory(interval: content.initialInterval)
    }

    private func selectPeriod(_ periodID: String) {
        guard
            let interval = PolymarketPriceInterval(rawValue: periodID),
            updateChartSession({ $0.selectPeriod(interval, now: Date()) }) == true
        else {
            return
        }

        renderChart()
        requestHistory(interval: interval)
    }

    private func loadHistory(interval: PolymarketPriceInterval) {
        guard updateChartSession({ $0.startLoading(interval) }) != nil else { return }

        renderChart()
        requestHistory(interval: interval)
    }

    private func requestHistory(interval: PolymarketPriceInterval) {
        guard let content = chartSetup.session?.content else { return }

        let outcomes = content.outcomes
        let query = content.historyQuery(for: interval)

        historyTask?.cancel()
        historyTask = runTask(in: self) { @MainActor viewModel in
            let history = await viewModel.priceHistory(outcomes: outcomes, query: query)

            guard !Task.isCancelled else { return }

            viewModel.updateChartSession {
                $0.applyHistory(history, interval: interval, fidelityMinutes: query.fidelityMinutes, now: Date())
            }
            viewModel.renderChart()
        }
    }

    private func priceHistory(
        outcomes: [PolymarketEventChartContent.Outcome],
        query: PolymarketPriceHistoryQuery
    ) async -> [String: [PolymarketPricePoint]]? {
        guard let clobService = chartServices?.clobService else { return nil }

        return await withTaskGroup(
            of: (String, [PolymarketPricePoint]?).self,
            returning: [String: [PolymarketPricePoint]]?.self
        ) { group in
            for tokenId in outcomes.map(\.tokenId) {
                group.addTask {
                    let points = try? await clobService.priceHistory(tokenId: tokenId, query: query)

                    return (tokenId, points)
                }
            }

            var history: [String: [PolymarketPricePoint]] = [:]

            for await (tokenId, points) in group {
                guard let points else {
                    group.cancelAll()
                    return nil
                }

                history[tokenId] = points
            }

            return history
        }
    }

    private func refreshChart(with event: PolymarketEvent) {
        guard let needsHistory = updateChartSession({ $0.refresh(with: event, now: Date()) }) else { return }

        renderChart(animatesChanges: true)

        if needsHistory, let interval = chartSetup.session?.loadingInterval {
            requestHistory(interval: interval)
        }
    }

    private func renderChart(animatesChanges: Bool = false) {
        guard let session = chartSetup.session else { return }

        let model = session.chartModel(
            now: Date(),
            legendLineCount: legendLineCount,
            animatesChanges: animatesChanges,
            onSelectPeriod: { [weak self] periodID in self?.selectPeriod(periodID) }
        )

        if let model {
            chart = .loaded(model)
        } else {
            chart = session.isLoadingHistory ? .loading : .failed
        }
    }

    @discardableResult
    private func updateChartSession<Result>(_ change: (inout PolymarketEventChartSession) -> Result) -> Result? {
        guard case .ready(var session) = chartSetup else { return nil }

        let result = change(&session)
        chartSetup = .ready(session)
        return result
    }
}

// MARK: - State

extension PolymarketEventDetailsViewModel {
    enum ViewAction {
        case onAppear
        case onDisappear
        case close
        case retry
        case toggleClosedMarkets
        case retryChart
        case expandDescription
    }
}

extension PolymarketEventDetailsViewModel {
    enum State {
        case loading
        case content(PolymarketEventDetailsContent)
        case failed(Failure)
    }

    struct ChartServices {
        let clobService: PolymarketCLOBService
        let sportsService: PolymarketEventSportsService
    }

    enum ChartState {
        case loading
        case loaded(PolymarketProbabilityChart.Model)
        case failed
        case unavailable
    }

    enum Failure {
        case notFound
        case generic

        init(error: Error) {
            guard case .http(let statusCode, _) = error as? PolymarketAPIError else {
                self = .generic
                return
            }

            self = statusCode == Constants.notFoundStatusCode ? .notFound : .generic
        }
    }
}

// MARK: - Constants

private extension PolymarketEventDetailsViewModel {
    enum Constants {
        static let pollInterval: UInt64 = 10_000_000_000
        static let silentRetryDelay: TimeInterval = 2
        static let toastTopPadding: CGFloat = 16
        static let notFoundStatusCode = 404
    }
}

// MARK: - Chart setup

private extension PolymarketEventDetailsViewModel {
    enum ChartSetup {
        case unresolved
        case resolvingSports(Task<Void, Never>)
        case sportsFailed
        case unavailable(PolymarketEventSports?)
        case ready(PolymarketEventChartSession)

        var session: PolymarketEventChartSession? {
            guard case .ready(let session) = self else { return nil }

            return session
        }

        func cancel() {
            guard case .resolvingSports(let task) = self else { return }

            task.cancel()
        }
    }
}

// MARK: - Sports match

private extension PolymarketEvent {
    var isSportsMatch: Bool {
        !teams.isEmpty || game != nil
    }
}
