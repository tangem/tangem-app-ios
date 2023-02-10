//
//  ExchangeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExchangeManager {
    /// Delegate for view updates
    func setDelegate(_ delegate: ExchangeManagerDelegate)

    /// Items which currently to swapping
    func getExchangeItems() -> ExchangeItems

    /// Current manager state
    func getAvailabilityState() -> ExchangeAvailabilityState

    /// Update swapping items and reload rates
    func update(exchangeItems: ExchangeItems)

    /// Update amount for swap
    func update(amount: Decimal?)

    /// Checking that decimal value available for exchange without approved
    /// Only for tokens
    func isEnoughAllowance() -> Bool

    /// Refresh main values
    func refresh(type: ExchangeManagerRefreshType)

    /// Call it to save transaction in pending list
    func didSendApprovingTransaction(exchangeTxData: ExchangeTransactionDataModel)

    /// Call it to signal success swap and stop timer
    func didSendSwapTransaction(exchangeTxData: ExchangeTransactionDataModel)
}
