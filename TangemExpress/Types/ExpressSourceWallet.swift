//
//  ExpressSourceWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressSourceWallet: Hashable {
    public let address: String
    public let currency: ExpressWalletCurrency
    public let feeCurrency: ExpressWalletCurrency
    public let feeProvider: FeeProvider
    public let allowanceProvider: AllowanceProvider
    public let balanceProvider: BalanceProvider

    var isFeeCurrency: Bool { currency == feeCurrency }

    var feeCurrencyHasPositiveBalance: Bool {
        balanceProvider.getFeeCurrencyBalance() > 0
    }

    public init(
        address: String,
        currency: ExpressWalletCurrency,
        feeCurrency: ExpressWalletCurrency,
        feeProvider: FeeProvider,
        allowanceProvider: AllowanceProvider,
        balanceProvider: BalanceProvider
    ) {
        self.address = address
        self.currency = currency
        self.feeCurrency = feeCurrency
        self.feeProvider = feeProvider
        self.allowanceProvider = allowanceProvider
        self.balanceProvider = balanceProvider
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(currency)
        hasher.combine(feeCurrency)
    }

    public static func == (lhs: ExpressSourceWallet, rhs: ExpressSourceWallet) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
