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
    public let amount: Decimal
    public let providerInfo: ProviderInfo
    public let operationType: ExpressOperationType

    public init(
        source: SourceWalletInfo,
        destination: DestinationWalletInfo,
        amount: Decimal,
        providerInfo: ProviderInfo,
        operationType: ExpressOperationType
    ) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.providerInfo = providerInfo
        self.operationType = operationType
    }

    func sourceAmountWEI() -> String {
        let wei = source.currency.convertToWEI(value: amount).stringValue
        return wei
    }
}

public extension ExpressSwappableDataItem {
    struct SourceWalletInfo {
        let address: String
        let currency: ExpressWalletCurrency
        let feeCurrency: ExpressWalletCurrency
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
