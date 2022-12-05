//
//  ExchangeManagerUtil.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeManagerUtil {
    public init() {}

    /// Use this method for checking that blockchain available for exchange
    public func networkIsAvailableForExchange(networkId: String) -> Bool {
        ExchangeBlockchain(networkId: networkId) != nil
    }
}
