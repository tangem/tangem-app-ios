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
    func getNetworksAvailableToSwap() -> [String]

    /// Items which currently to swapping
    func getExchangeItems() -> ExchangeItems

    /// Update swapping items and reload rates
    func update(exchangeItems: ExchangeItems)

    /// Update amount for swap
    func update(amount: Decimal)

    /// Checking that decimal value available for exchange without approved
    /// Only for tokens
    func isAvailableForExchange(amount: Decimal) -> Bool

    /// Get data model with data which should be viewed to user for approve
    func getApprovedDataModel() async -> ExchangeApprovedDataModel?

    /// Approve and swap items
    func approveAndSwapItems()

    /// User request swap items
    func swapItems()
}
