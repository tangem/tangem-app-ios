//
//  TangemPayVirtualAccountFee.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

struct TangemPayVirtualAccountFee: Hashable, Identifiable {
    let id: String
    let title: String
    let value: String
}

extension TangemPayVirtualAccountFee {
    init?(response: TangemPayFeeResponse) {
        guard let name = response.name, !name.isEmpty else {
            return nil
        }

        self.init(id: response.type, title: name, value: Self.format(amount: response.amount, currency: response.currency))
    }

    init?(credentials: TangemPayBankCredentialsResponse) {
        guard
            let rail = credentials.rail,
            !rail.isEmpty,
            let amount = credentials.fee?.flatAmount
        else {
            return nil
        }

        self.init(id: rail, title: rail, value: Self.format(amount: amount, currency: Constants.bankCredentialsFeeCurrency))
    }
}

// MARK: - Formatting

private extension TangemPayVirtualAccountFee {
    enum Constants {
        static let bankCredentialsFeeCurrency = "USD"
    }

    static func format(amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = amount.scale == 0 ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }
}

// MARK: - Previews

#if DEBUG
extension [TangemPayVirtualAccountFee] {
    static let previews: Self = [
        .init(id: "ACH_ONRAMP", title: "ACH", value: "$0"),
        .init(id: "FEDWIRE_ONRAMP", title: "Fedwire", value: "$0"),
    ]
}
#endif
