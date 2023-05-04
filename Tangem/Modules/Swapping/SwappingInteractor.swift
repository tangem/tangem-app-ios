//
//  SwappingInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

class SwappingInteractor {
    // MARK: - Public

    public let state = CurrentValueSubject<SwappingAvailabilityState, Never>(.idle)

    // MARK: - Dependencies

    private let swappingManager: SwappingManager

    // MARK: - Private

    private var updateStateTask: Task<Void, Error>?

    init(swappingManager: SwappingManager) {
        self.swappingManager = swappingManager
    }
}

// MARK: - Public

extension SwappingInteractor {
    func getAvailabilityState() -> SwappingAvailabilityState {
        state.value
    }

    func getSwappingItems() -> SwappingItems {
        swappingManager.getSwappingItems()
    }

    func getReferrerAccountFee() -> Decimal? {
        swappingManager.getReferrerAccount()?.fee
    }

    func update(swappingItems: SwappingItems) async -> SwappingItems {
        updateState(.idle)
        swappingManager.update(swappingItems: swappingItems)
        return await swappingManager.refreshBalances()
    }

    func update(amount: Decimal?) {
        swappingManager.update(amount: amount)
        refresh(type: .full)
    }

    func refresh(type: SwappingManagerRefreshType) {
        AppLog.shared.debug("[Swap] SwappingInteractor received the request for refresh with \(type)")

        guard let amount = swappingManager.getAmount(), amount > 0 else {
            updateState(.idle)
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor start refreshing task")
        updateState(.loading(type))
        updateStateTask = Task {
            await updateState(swappingManager.refresh(type: type))
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor cancel the refreshing task")

        updateStateTask?.cancel()
        updateStateTask = nil
    }

    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData) {
        swappingManager.didSendApprovingTransaction(swappingTxData: swappingTxData)
        refresh(type: .full)
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        updateState(.idle)
    }
}

// MARK: - Private

extension SwappingInteractor {
    func updateState(_ state: SwappingAvailabilityState) {
        AppLog.shared.debug("[Swap] SwappingInteractor will update state to \(state)")

        self.state.send(state)
    }
}
