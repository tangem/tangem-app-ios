//
//  TangemPayDepositLimitFormatter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

enum TangemPayDepositLimitFormatter {
    static func format(_ depositLimit: TangemPayBankCredentialsResponse.DepositLimit?) -> String {
        let amount = depositLimit?.amount ?? Constants.defaultDailyDepositLimit

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = Constants.currencyCode
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(Constants.currencyCode)"
    }
}

// MARK: - Constants

private extension TangemPayDepositLimitFormatter {
    enum Constants {
        static let defaultDailyDepositLimit: Decimal = 10_000
        static let currencyCode = "USD"
    }
}
