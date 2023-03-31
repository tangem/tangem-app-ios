//
//  SwappingManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol SwappingManager {
    /// Delegate for view updates
    func setDelegate(_ delegate: SwappingManagerDelegate)

    /// Items which currently to swapping
    func getSwappingItems() -> SwappingItems

    /// Current manager state
    func getAvailabilityState() -> SwappingAvailabilityState

    /// Beneficiary account
    func getReferrerAccount() -> SwappingReferrerAccount?

    /// Update swapping items and reload rates
    func update(swappingItems: SwappingItems)

    /// Update amount for swap
    func update(amount: Decimal?)

    /// Checking that decimal value available for swapping without approved
    /// Only for tokens
    func isEnoughAllowance() -> Bool

    /// Refresh main values
    func refresh(type: SwappingManagerRefreshType)

    /// Call it to save transaction in pending list
    func didSendApprovingTransaction(swappingTxData: SwappingTransactionData)

    /// Call it to signal success swap and stop timer
    func didSendSwapTransaction(swappingTxData: SwappingTransactionData)
}
