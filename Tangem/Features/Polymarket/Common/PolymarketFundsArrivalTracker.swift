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

    private var windowTask: Task<Void, Never>?
    private var balanceSubscription: AnyCancellable?

    init(
        balancePublisher: AnyPublisher<Decimal?, Never>,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.balancePublisher = balancePublisher
        self.delayProvider = delayProvider
    }

    deinit {
        windowTask?.cancel()
    }

    func startAwaitingFunds() {
        isAwaitingFunds = true
        openWindow()
    }

    func startAwaitingWithdrawal() {
        openWindow()
    }
}

// MARK: - The window

private extension PolymarketFundsArrivalTracker {
    func openWindow() {
        windowTask?.cancel()
        isBalanceChangeExpected = true
        observeBalance()

        windowTask = Task { @MainActor [weak self] in
            try? await self?.delayProvider.wait(for: Constants.windowDuration)

            guard !Task.isCancelled else { return }

            self?.closeWindow()
        }
    }

    func observeBalance() {
        balanceSubscription = balancePublisher
            .compactMap { $0 }
            .removeDuplicates()
            .dropFirst()
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
    }
}

// MARK: - Constants

private extension PolymarketFundsArrivalTracker {
    enum Constants {
        static let windowDuration: TimeInterval = 90
    }
}
