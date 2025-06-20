//
//  ExpressSwappableQuoteItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct ExpressSwappableQuoteItem {
    public let source: ExpressWalletCurrency
    public let destination: ExpressWalletCurrency
    public let amount: Decimal
    public let providerInfo: ProviderInfo

    public init(
        source: ExpressWalletCurrency,
        destination: ExpressWalletCurrency,
        amount: Decimal,
        providerInfo: ProviderInfo
    ) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.providerInfo = providerInfo
    }

    func sourceAmountWEI() -> String {
        let wei = source.convertToWEI(value: amount) as NSDecimalNumber
        return wei.stringValue
    }
}

public extension ExpressSwappableQuoteItem {
    struct ProviderInfo {
        let id: ExpressProvider.Id
        let type: ExpressProviderType
    }
}
