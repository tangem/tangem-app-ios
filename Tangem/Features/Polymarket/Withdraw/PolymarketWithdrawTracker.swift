//
//  PolymarketWithdrawTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

protocol PolymarketWithdrawTracking: Sendable {
    func track(_ record: PolymarketWithdrawRecord, deadline: Date) async
}

actor PolymarketWithdrawTracker {
    nonisolated var statePublisher: AnyPublisher<PolymarketWithdrawState?, Never> {
        _state.eraseToAnyPublisher()
    }

    private nonisolated let _state = CurrentValueSubject<PolymarketWithdrawState?, Never>(nil)
    private let withdrawService: PolymarketWithdrawService
    private let store: PolymarketWithdrawRecordStore
    private let delayProvider: PollDelayProvider
    private let serverClock: PolymarketServerClock

    private var entry: PolymarketWithdrawRecordStore.Entry?
    private var pollingTask: Task<Void, Never>?
    private var expiryTask: Task<Void, Never>?

    init(
        withdrawService: PolymarketWithdrawService,
        store: PolymarketWithdrawRecordStore,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
        serverClock: PolymarketServerClock = InjectedValues[\.polymarketServerClock]
    ) {
        self.withdrawService = withdrawService
        self.store = store
        self.delayProvider = delayProvider
        self.serverClock = serverClock
    }

    deinit {
        pollingTask?.cancel()
        expiryTask?.cancel()
    }

    func track(_ record: PolymarketWithdrawRecord, deadline: Date) {
        PolymarketLogger.info("Tracking the withdrawal \(record.transactionId), submitted as \(record.state)")

        let entry = PolymarketWithdrawRecordStore.Entry(
            record: record,
            deadline: deadline,
            settledAt: record.state.isTerminal ? serverClock.now : nil
        )
        store.save(entry)
        follow(entry)
    }

    func resume() {
        guard let entry = store.entry() else { return }

        PolymarketLogger.info("Resuming the withdrawal \(entry.record.transactionId), last seen as \(entry.record.state)")
        follow(entry)
    }
}

// MARK: - PolymarketWithdrawTracking protocol conformance

extension PolymarketWithdrawTracker: PolymarketWithdrawTracking {}

// MARK: - Private implementation

private extension PolymarketWithdrawTracker {
    enum Verdict {
        case keepPolling
        case stop
    }

    func follow(_ entry: PolymarketWithdrawRecordStore.Entry) {
        pollingTask?.cancel()
        pollingTask = nil
        expiryTask?.cancel()
        expiryTask = nil
        self.entry = entry

        let record = entry.record
        let remaining = timeLeft(for: entry)

        guard !record.state.isTerminal else {
            guard remaining > 0 else {
                forget(record, reason: "its outcome was shown long enough")
                return
            }

            _state.send(record.state)
            scheduleExpiry(of: record, in: remaining)
            return
        }

        _state.send(record.state)
        scheduleExpiry(of: record, in: max(remaining, Constants.settlementGrace))

        pollingTask = Task { [weak self, withdrawService, delayProvider] in
            try? await delayProvider.wait(for: Constants.interval)

            let polling = PollingSequence(
                interval: Constants.interval,
                request: { try await withdrawService.record(ofWithdrawal: record.transactionId) },
                delayProvider: delayProvider
            )

            for await result in polling {
                guard let self, await apply(result) == .keepPolling else { return }
            }
        }
    }

    func apply(_ result: Result<PolymarketWithdrawRecord, Error>) -> Verdict {
        guard !Task.isCancelled, let entry else { return .stop }

        switch result {
        case .success(let polled):
            let updated = entry.updated(with: polled, settledAt: polled.state.isTerminal ? serverClock.now : nil)
            self.entry = updated

            if polled != entry.record {
                store.save(updated)
            }

            _state.send(polled.state)

            if polled.state.isTerminal {
                PolymarketLogger.info("The withdrawal \(polled.transactionId) settled as \(polled.state)")
                scheduleExpiry(of: polled, in: timeLeft(for: updated))
                return .stop
            }

            guard timeLeft(for: updated) > 0 else {
                forget(polled, reason: "its deadline and the settlement grace passed")
                return .stop
            }

            return .keepPolling

        case .failure(let error):
            guard let refusal = error as? PolymarketWithdrawError, refusal.endsTracking else {
                return .keepPolling
            }

            PolymarketLogger.error("The backend refused the withdrawal status", error: refusal)
            forget(entry.record, reason: "the backend refused to report on it")

            return .stop
        }
    }

    func scheduleExpiry(of record: PolymarketWithdrawRecord, in remaining: TimeInterval) {
        expiryTask?.cancel()

        expiryTask = Task { [weak self, delayProvider] in
            try? await delayProvider.wait(for: remaining)

            await self?.expire(record)
        }
    }

    func expire(_ record: PolymarketWithdrawRecord) {
        guard !Task.isCancelled else { return }

        forget(record, reason: record.state.isTerminal ? "its outcome was shown long enough" : "its deadline and the settlement grace passed")
    }

    func forget(_ record: PolymarketWithdrawRecord, reason: String) {
        PolymarketLogger.info("Forgetting the withdrawal \(record.transactionId), last seen as \(record.state): \(reason)")
        pollingTask?.cancel()
        pollingTask = nil
        expiryTask?.cancel()
        expiryTask = nil
        entry = nil
        store.delete()
        _state.send(nil)
    }

    func timeLeft(for entry: PolymarketWithdrawRecordStore.Entry) -> TimeInterval {
        let expiresAt = entry.settledAt.map { $0.addingTimeInterval(Constants.outcomeNoticeLifetime) }
            ?? entry.deadline.addingTimeInterval(Constants.settlementGrace)

        return expiresAt.timeIntervalSince(serverClock.now)
    }
}

// MARK: - Which refusals end the tracking

private extension PolymarketWithdrawError {
    var endsTracking: Bool {
        switch self {
        case .badRequest, .unauthorized, .foreignDepositWallet, .notFound, .conflict, .relayerRejected:
            true
        case .upstreamUnavailable, .cancelled, .other:
            false
        }
    }
}

// MARK: - Constants

private extension PolymarketWithdrawTracker {
    enum Constants {
        static let interval: TimeInterval = 3
        static let settlementGrace: TimeInterval = 3 * 60
        static let outcomeNoticeLifetime: TimeInterval = 90
    }
}
