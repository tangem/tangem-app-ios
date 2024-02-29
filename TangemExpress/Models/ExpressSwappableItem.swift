//
//  ExpressSwappableItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressSwappableItem {
    public let source: ExpressWallet
    public let destination: ExpressWallet
    public let amount: Decimal
    public let providerId: ExpressProvider.Id

    public init(
        source: ExpressWallet,
        destination: ExpressWallet,
        amount: Decimal,
        providerId: ExpressProvider.Id
    ) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.providerId = providerId
    }

    func sourceAmountWEI() -> String {
        let wei = source.convertToWEI(value: amount) as NSDecimalNumber
        return wei.stringValue
    }
}
