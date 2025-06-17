//
//  ExpressWallet.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    var expressCurrency: ExpressWalletCurrency { get }
    var expressFeeCurrency: ExpressWalletCurrency { get }
    var expressFeeProvider: FeeProvider { get }
    var expressAllowanceProvider: AllowanceProvider { get }
    var expressBalanceProvider: any BalanceProvider { get }

    var defaultAddressString: String { get }
    var decimalCount: Int { get }

    var feeCurrencyDecimalCount: Int { get }
    var isFeeCurrency: Bool { get }

    func getBalance() throws -> Decimal
    func getFeeCurrencyBalance() -> Decimal
}

public extension ExpressWallet {
    var feeCurrencyHasPositiveBalance: Bool {
        getFeeCurrencyBalance() > 0
    }

    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
