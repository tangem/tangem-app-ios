//
//  ExchangeManagerDelegate.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExchangeManagerDelegate: AnyObject {
    func exchangeManager(_ manager: ExchangeManager, didUpdate exchangeItems: ExchangeItems)
    func exchangeManager(_ manager: ExchangeManager, didUpdate availabilityState: ExchangeAvailabilityState)
    func exchangeManager(_ manager: ExchangeManager, didUpdate availabilityForExchange: Bool)
    func exchangeManager(_ manager: ExchangeManager, didUpdate sendingFiatAmount: Decimal)
}
