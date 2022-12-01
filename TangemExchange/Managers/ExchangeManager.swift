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

    /// Available network for selected as target to swap
    func getCurrentExchangeBlockchain() -> ExchangeBlockchain

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
    func isAvailableForExchange() -> Bool

    /// Approve and swap items
    func approveAndSwapItems()

    /// User request swap items
    func swapItems()
}
