//
//  PolymarketMainActivityHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

final class PolymarketMainActivityHandler {
    typealias Handler = @MainActor (PolymarketPosition?) async -> Void

    private let fundsArrivalTracker: PolymarketFundsArrivalTracker
    private let refreshCenter: PolymarketMainRefreshCenter

    private var tradedHandler: Handler?
    private var claimedHandler: Handler?
    private var orderTask: Task<Void, Never>?
    private var claimTask: Task<Void, Never>?

    init(fundsArrivalTracker: PolymarketFundsArrivalTracker, refreshCenter: PolymarketMainRefreshCenter) {
        self.fundsArrivalTracker = fundsArrivalTracker
        self.refreshCenter = refreshCenter
    }

    deinit {
        orderTask?.cancel()
        claimTask?.cancel()
    }

    func setTradedHandler(_ handler: @escaping Handler) {
        tradedHandler = handler
    }

    func setClaimedHandler(_ handler: @escaping Handler) {
        claimedHandler = handler
    }

    func orderPlaced(awaiting indexing: PolymarketOrderIndexing) {
        orderTask?.cancel()

        fundsArrivalTracker.startAwaitingBalanceChange()

        let refreshCenter = refreshCenter
        let handler = tradedHandler

        orderTask = Task { @MainActor in
            await refreshCenter.refresh(.balance)

            let traded = await indexing.value

            guard !Task.isCancelled else { return }

            await refreshCenter.refresh(.balance)

            guard !Task.isCancelled else { return }

            await handler?(traded)
        }
    }

    func claimed(_ position: PolymarketPosition?) {
        claimTask?.cancel()

        fundsArrivalTracker.startAwaitingBalanceChange()

        let refreshCenter = refreshCenter
        let handler = claimedHandler

        claimTask = Task { @MainActor in
            await refreshCenter.refresh(.balance)

            guard !Task.isCancelled else { return }

            await handler?(position)
        }
    }
}
