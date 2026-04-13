//
//  ExpressSwappableDataItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct ExpressSwappableDataItem {
    public let source: SourceWalletInfo
    public let destination: DestinationWalletInfo
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let providerInfo: ProviderInfo
    public let operationType: ExpressOperationType
    public let quoteId: String?

    public init(
        source: SourceWalletInfo,
        destination: DestinationWalletInfo,
        amountType: ExpressAmountType,
        rateType: ExpressProviderRateType,
        providerInfo: ProviderInfo,
        operationType: ExpressOperationType,
        quoteId: String? = nil
    ) {
        self.source = source
        self.destination = destination
        self.amountType = amountType
        self.rateType = rateType
        self.providerInfo = providerInfo
        self.operationType = operationType
        self.quoteId = quoteId
    }

    public var amount: Decimal {
        amountType.amount
    }

    func sourceAmountWEI() -> String? {
        switch amountType {
        case .from(let value):
            let wei = source.currency.convertToWEI(value: value).stringValue
            return wei
        case .to:
            return nil
        }
    }

    func destinationAmountWEI() -> String? {
        switch amountType {
        case .to(let value):
            let wei = destination.currency.convertToWEI(value: value).stringValue
            return wei
        case .from:
            return nil
        }
    }
}

public extension ExpressSwappableDataItem {
    struct SourceWalletInfo {
        let address: String
        let currency: ExpressWalletCurrency
        let coinCurrency: ExpressWalletCurrency
    }

    struct DestinationWalletInfo {
        let address: String
        let currency: ExpressWalletCurrency
        let extraId: String?
    }

    struct ProviderInfo {
        let id: ExpressProvider.Id
        let type: ExpressProviderType
    }
}
