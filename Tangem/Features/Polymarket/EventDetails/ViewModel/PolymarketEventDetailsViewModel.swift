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
import TangemUI
import TangemUIUtils

final class PolymarketEventDetailsViewModel: ObservableObject, Identifiable {
    @Published private(set) var state: State = .loading
    @Published private(set) var isDescriptionExpanded = false
    @Published private(set) var isClosedMarketsExpanded = false

    let eventID: String

    private let category: PolymarketCategory?
    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider
    private let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
    private weak var coordinator: PolymarketEventDetailsRoutable?

    private var loadingTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var hasReportedStaleData = false
    private var isVisible = false
    private var isInBackground = false
    private let appStateObserver = AppStateObserver()

    init(
        eventID: String,
        category: PolymarketCategory?,
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void,
        coordinator: PolymarketEventDetailsRoutable
    ) {
        self.eventID = eventID
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
        case .expandDescription:
            expandDescription()
        }
    }

    // MARK: - Actions

    private func load() {
        loadingTask?.cancel()
        stopPolling()
        state = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let event = try await viewModel.event()
                viewModel.state = .content(viewModel.makeContent(from: event))
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
        do {
            let event = try await event()
            state = .content(makeContent(from: event))
            hasReportedStaleData = false
        } catch {
            guard !error.isCancellationError else { return }

            PolymarketLogger.error("Event \(eventID) refresh failed, keeping the last data", error: error)

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
        .make(event: event, category: category) { [weak self] market, outcome in
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
}

// MARK: - State

extension PolymarketEventDetailsViewModel {
    enum ViewAction {
        case onAppear
        case onDisappear
        case close
        case retry
        case toggleClosedMarkets
        case expandDescription
    }
}

extension PolymarketEventDetailsViewModel {
    enum State {
        case loading
        case content(PolymarketEventDetailsContent)
        case failed(Failure)
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
