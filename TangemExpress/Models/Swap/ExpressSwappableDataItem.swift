//
//  ExpressSwappableDataItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

public struct ExpressSwappableDataItem {
    public let source: SourceWalletInfo
    public let destination: DestinationWalletInfo
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let providerInfo: ProviderInfo
    public let operationType: ExpressOperationType
    public let quoteId: String?

    public var amount: Decimal {
        amountType.amount
    }

    /// For DEX/DEXBridge providers, returns the yield contract address if available; otherwise falls back to the regular source address.
    var dexFromAddress: String {
        switch providerInfo.type {
        case .dex, .dexBridge:
            return source.yieldContractAddress ?? source.address
        case .cex, .onramp, .unknown:
            return source.address
        }
    }

    func sourceAmountWEI() throws -> String? {
        switch amountType {
        case .from(let value):
            let unscaled = try ScaledUIAmount.unscale(displayed: value, by: source.amountScale)
            // Unscaling can yield more precision than the token has, and the API only accepts whole units.
            let wei = source.currency.convertToWEI(value: unscaled).rounded(scale: 0, roundingMode: .down)
            return wei.stringValue
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

    /// Converts an on-chain source amount from a response back into the space the app displays.
    func displayedSourceAmount(_ amount: Decimal) -> Decimal {
        ScaledUIAmount.scale(onChain: amount, by: source.amountScale)
    }
}

public extension ExpressSwappableDataItem {
    struct SourceWalletInfo {
        let address: String
        let yieldContractAddress: String?
        let currency: ExpressWalletCurrency
        let coinCurrency: ExpressWalletCurrency
        let amountScale: Decimal?
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
