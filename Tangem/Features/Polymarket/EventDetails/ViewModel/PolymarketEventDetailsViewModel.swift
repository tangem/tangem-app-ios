//
//  PolymarketEventDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketEventDetailsViewModel: ObservableObject, Identifiable {
    @Published private(set) var state: State = .loading
    @Published private(set) var isDescriptionExpanded = false
    @Published private(set) var isClosedMarketsExpanded = false

    let eventID: String

    private let category: PolymarketCategory?
    private let apiProvider: PolymarketAPIProvider
    private let geoblockStateProvider: PolymarketGeoblockStateProvider?
    private let onOrderPlaced: @MainActor (PolymarketOrderIndexing?) -> Void
    private weak var coordinator: PolymarketEventDetailsRoutable?

    private var loadingTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?

    init(
        eventID: String,
        category: PolymarketCategory?,
        apiProvider: PolymarketAPIProvider,
        geoblockStateProvider: PolymarketGeoblockStateProvider?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing?) -> Void,
        coordinator: PolymarketEventDetailsRoutable
    ) {
        self.eventID = eventID
        self.category = category
        self.apiProvider = apiProvider
        self.geoblockStateProvider = geoblockStateProvider
        self.onOrderPlaced = onOrderPlaced
        self.coordinator = coordinator

        load()
    }

    deinit {
        loadingTask?.cancel()
        pollingTask?.cancel()
    }

    // MARK: - Actions

    func load() {
        loadingTask?.cancel()
        pollingTask?.cancel()
        state = .loading

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let event = try await viewModel.apiProvider.event(id: viewModel.eventID)
                viewModel.state = .content(viewModel.makeContent(from: event))
                viewModel.startPolling()
            } catch {
                guard !error.isCancellationError else { return }

                viewModel.state = .failed(Failure(error: error))
            }
        }
    }

    func dismiss() {
        coordinator?.dismissEventDetails()
    }

    func resumePolling() {
        guard pollingTask == nil, case .content = state else { return }

        startPolling()
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func expandDescription() {
        isDescriptionExpanded = true
    }

    func toggleClosedMarkets() {
        isClosedMarketsExpanded.toggle()
    }

    // MARK: - Loading

    private func startPolling() {
        pollingTask = Task { @MainActor [weak self] in
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
            let event = try await apiProvider.event(id: eventID)
            state = .content(makeContent(from: event))
        } catch {
            guard !error.isCancellationError else { return }

            PolymarketLogger.error("Event \(eventID) refresh failed, keeping the last data", error: error)
        }
    }

    private func makeContent(from event: PolymarketEvent) -> PolymarketEventDetailsContent {
        .make(event: event, category: category) { [weak self] market, outcome in
            self?.selectOutcome(market: market, outcome: outcome, eventTitle: event.title)
        }
    }

    private func selectOutcome(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String) {
        guard geoblockStateProvider?.state != .blocked else {
            coordinator?.openRegionWarning()
            return
        }

        coordinator?.openOrder(
            market: market,
            outcome: outcome,
            eventTitle: eventTitle,
            onPlaced: onOrderPlaced
        )
    }
}

// MARK: - State

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
        static let notFoundStatusCode = 404
    }
}
