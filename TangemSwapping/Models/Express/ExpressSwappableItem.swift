//
//  ExpressSwappableItem.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressSwappableItem {
    public let source: ExpressWallet
    public let destination: ExpressWallet
    public let amount: Decimal
    public let providerId: Int

    public init(
        source: ExpressWallet,
        destination: ExpressWallet,
        amount: Decimal,
        providerId: Int
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
