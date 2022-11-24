//
//  ExchangeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExchangeManager {
    /// Available network for selected as target to swap
    func getNetworksAvailableToSwap() -> [String]

    /// Items which currently to swapping
    func getExchangeItems() -> ExchangeItems

    /// Update swapping items and reload rates
    func update(exchangeItems: ExchangeItems)

    /// Checking that decimal value available for exchange withour approved
    /// Only for tokens
    func isAvailableForExchange(amount: Decimal) -> Bool
    
    /// Get data model with data which should be viewed to user for approve
    func getApprovedDataModel() -> ExchangeApprovedDataModel

    /// Approve and swap items
    func approveAndSwapItems()

    /// User request swap items
    func swapItems()
}
