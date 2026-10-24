//
//  PolymarketBalanceRefresher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class PolymarketBalanceRefresher {
    private let balanceProvider: PolymarketBalanceProvider
    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private let appStateObserver = AppStateObserver()

    private var loopTask: Task<Void, Never>?
    private var isInBackground = false
    private var bag: Set<AnyCancellable> = []

    init(
        balanceProvider: PolymarketBalanceProvider,
        fundsArrivalTracker: PolymarketFundsArrivalTracker
    ) {
        self.balanceProvider = balanceProvider
        self.fundsArrivalTracker = fundsArrivalTracker
    }

    deinit {
        loopTask?.cancel()
    }

    func start() {
        bindFundsArrival()
        bindApplicationState()
        startLoop()
    }

    func refreshNow() {
        Task { @MainActor [weak self] in
            await self?.refresh()
        }
    }

    @MainActor
    func refresh() async {
        await balanceProvider.refresh(scope: .full)
    }
}

// MARK: - Binding

private extension PolymarketBalanceRefresher {
    func bindFundsArrival() {
        fundsArrivalTracker
            .$isBalanceChangeExpected
            .removeDuplicates()
            .filter { $0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { refresher, _ in
                guard !refresher.isInBackground else { return }

                refresher.startLoop()
            }
            .store(in: &bag)
    }

    func bindApplicationState() {
        appStateObserver.start { [weak self] isInBackground in
            guard let self else { return }

            self.isInBackground = isInBackground

            if isInBackground {
                stopLoop()
            } else {
                startLoop()
            }
        }
    }
}

// MARK: - Loop

private extension PolymarketBalanceRefresher {
    func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
    }

    func startLoop() {
        loopTask?.cancel()

        loopTask = Task { @MainActor [weak self] in
            await self?.refresh()

            while !Task.isCancelled {
                let interval = self?.fundsArrivalTracker.isBalanceChangeExpected == true
                    ? Constants.expectedChangeInterval
                    : Constants.interval

                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled, let self else { return }

                let scope: PolymarketBalanceRefreshScope = fundsArrivalTracker.isBalanceChangeExpected ? .availableOnly : .full

                await balanceProvider.refresh(scope: scope)
            }
        }
    }
}

// MARK: - Constants

private extension PolymarketBalanceRefresher {
    enum Constants {
        static let interval: TimeInterval = 30
        static let expectedChangeInterval: TimeInterval = 5
    }
}
