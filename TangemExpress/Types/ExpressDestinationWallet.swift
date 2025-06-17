//
//  ExpressDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressDestinationWallet: Hashable {
    public let currency: ExpressWalletCurrency
    public let address: String?

    public init(currency: ExpressWalletCurrency, address: String?) {
        self.currency = currency
        self.address = address
    }
}
