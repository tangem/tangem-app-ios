//
//  ExpressSwappableQuoteItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

public struct ExpressSwappableQuoteItem {
    public let source: ExpressWalletCurrency
    public let destination: ExpressWalletCurrency
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let providerInfo: ProviderInfo
    public let sourceAmountScale: Decimal?

    public var amount: Decimal {
        amountType.amount
    }

    func sourceAmountWEI() throws -> String? {
        switch amountType {
        case .from(let value):
            let unscaled = try ScaledUIAmount.unscale(displayed: value, by: sourceAmountScale)
            // Unscaling can yield more precision than the token has, and the API only accepts whole units.
            let wei = source.convertToWEI(value: unscaled).rounded(scale: 0, roundingMode: .down)
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

    /// Converts an on-chain source amount from a response back into the space the app displays.
    func displayedSourceAmount(_ amount: Decimal) -> Decimal {
        ScaledUIAmount.scale(onChain: amount, by: sourceAmountScale)
    }
}

public extension ExpressSwappableQuoteItem {
    struct ProviderInfo {
        let id: ExpressProvider.Id
        let type: ExpressProviderType
    }
}
