//
//  SwappingManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct SwappingManagerMock: SwappingManager {
    func setDelegate(_ delegate: TangemSwapping.SwappingManagerDelegate) {}

    func getSwappingItems() -> TangemSwapping.SwappingItems {
        SwappingItems(source: .mock, destination: .mock)
    }

    func getAvailabilityState() -> SwappingAvailabilityState { .idle }

    func getReferrerAccount() -> SwappingReferrerAccount? { nil }

    func update(swappingItems: SwappingItems) {}

    func update(amount: Decimal?) {}

    func isEnoughAllowance() -> Bool { true }

    func refresh(type: SwappingManagerRefreshType) {}

    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData) {}
    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {}
}
