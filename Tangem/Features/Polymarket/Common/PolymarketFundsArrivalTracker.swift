//
//  PolymarketFundsArrivalTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class PolymarketFundsArrivalTracker: ObservableObject {
    @Published private(set) var isAwaitingFunds = false
    @Published private(set) var isBalanceChangeExpected = false

    private let balancePublisher: AnyPublisher<Decimal?, Never>
    private let delayProvider: PollDelayProvider

    private let latestBalance = OSAllocatedUnfairLock<Decimal?>(initialState: nil)

    private var windowTask: Task<Void, Never>?
    private var onSettled: (() -> Void)?
    private var balanceSubscription: AnyCancellable?
    private var latestBalanceSubscription: AnyCancellable?

    var currentBalance: Decimal? {
        latestBalance.withLock { $0 }
    }

    init(
        balancePublisher: AnyPublisher<Decimal?, Never>,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.balancePublisher = balancePublisher
        self.delayProvider = delayProvider

        trackLatestBalance()
    }

    deinit {
        windowTask?.cancel()
    }

    func startAwaitingFunds(since baseline: Decimal? = nil, onSettled: (() -> Void)? = nil) {
        self.onSettled = onSettled

        guard !hasChanged(since: baseline) else {
            closeWindow()
            return
        }

        isAwaitingFunds = true
        openWindow(since: baseline)
    }

    func startAwaitingBalanceChange(since baseline: Decimal? = nil) {
        guard !hasChanged(since: baseline) else {
            closeWindow()
            return
        }

        openWindow(since: baseline)
    }
}

// MARK: - The window

private extension PolymarketFundsArrivalTracker {
    func trackLatestBalance() {
        latestBalanceSubscription = balancePublisher
            .compactMap { $0 }
            .sink { [latestBalance] balance in
                latestBalance.withLock { $0 = balance }
            }
    }

    func hasChanged(since baseline: Decimal?) -> Bool {
        guard let baseline, let currentBalance else { return false }

        return currentBalance != baseline
    }

    func openWindow(since baseline: Decimal?) {
        windowTask?.cancel()
        isBalanceChangeExpected = true
        observeBalance(since: baseline)

        windowTask = Task { @MainActor [weak self] in
            try? await self?.delayProvider.wait(for: Constants.windowDuration)

            guard !Task.isCancelled else { return }

            self?.closeWindow()
        }
    }

    func observeBalance(since baseline: Decimal?) {
        let balances = balancePublisher
            .compactMap { $0 }
            .removeDuplicates()

        let changes = baseline.map { baseline in balances.filter { $0 != baseline }.eraseToAnyPublisher() }
            ?? balances.dropFirst().eraseToAnyPublisher()

        balanceSubscription = changes
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { tracker, _ in
                tracker.closeWindow()
            }
    }

    func closeWindow() {
        windowTask?.cancel()
        windowTask = nil
        balanceSubscription = nil
        isBalanceChangeExpected = false
        isAwaitingFunds = false

        let settled = onSettled
        onSettled = nil
        settled?()
    }
}

// MARK: - Constants

private extension PolymarketFundsArrivalTracker {
    enum Constants {
        static let windowDuration: TimeInterval = 90
    }
}
