//
//  ExchangeManagerDelegate.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExchangeManagerDelegate: AnyObject {
    func exchangeManagerDidUpdate(availabilityState: ExchangeAvailabilityState)
    func exchangeManagerDidUpdate(swappingModel: ExchangeDataModel)
}
