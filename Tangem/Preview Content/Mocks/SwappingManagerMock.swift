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
    func getAmount() -> Decimal? { 0.1 }

    func getSwappingApprovePolicy() -> SwappingApprovePolicy { .unlimited }

    func getSwappingItems() -> TangemSwapping.SwappingItems {
        SwappingItems(source: .mock, destination: .mock)
    }

    func getReferrerAccount() -> SwappingReferrerAccount? { nil }

    func getSwappingGasPricePolicy() -> SwappingGasPricePolicy { .normal }

    func update(swappingItems: SwappingItems) {}

    func update(amount: Decimal?) {}

    func update(approvePolicy: SwappingApprovePolicy) {}

    func update(gasPricePolicy: SwappingGasPricePolicy) {}

    func isEnoughAllowance() -> Bool { true }

    func refreshBalances() async -> SwappingItems { getSwappingItems() }
    func refresh(type: TangemSwapping.SwappingManagerRefreshType) async -> TangemSwapping.SwappingAvailabilityState { .idle }

    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {}
}
