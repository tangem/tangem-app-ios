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
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let providerInfo: ProviderInfo

    public init(
        source: ExpressWalletCurrency,
        destination: ExpressWalletCurrency,
        amountType: ExpressAmountType,
        rateType: ExpressProviderRateType,
        providerInfo: ProviderInfo
    ) {
        self.source = source
        self.destination = destination
        self.amountType = amountType
        self.rateType = rateType
        self.providerInfo = providerInfo
    }

    public var amount: Decimal {
        amountType.amount
    }

    func sourceAmountWEI() -> String? {
        switch amountType {
        case .from(let value):
            let wei = source.convertToWEI(value: value) as NSDecimalNumber
            return wei.stringValue
        case .to:
            return nil
        }
    }

    func destinationAmountWEI() -> String? {
        switch amountType {
        case .to(let value):
            let wei = destination.convertToWEI(value: value) as NSDecimalNumber
            return wei.stringValue
        case .from:
            return nil
        }
    }
}

public extension ExpressSwappableQuoteItem {
    struct ProviderInfo {
        let id: ExpressProvider.Id
        let type: ExpressProviderType
    }
}
