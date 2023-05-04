//
//  SwappingManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol SwappingManager {
    func getAmount() -> Decimal?
    func getSwappingItems() -> SwappingItems
    func getReferrerAccount() -> SwappingReferrerAccount?
    func isEnoughAllowance() -> Bool

    func update(swappingItems: SwappingItems)
    func update(amount: Decimal?)
    func update(approvePolicy: SwappingApprovePolicy)

    @discardableResult
    func refreshBalances() async -> SwappingItems
    func refresh(type: SwappingManagerRefreshType) async -> SwappingAvailabilityState

    /// Call it to save transaction in pending list
    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData)
}
