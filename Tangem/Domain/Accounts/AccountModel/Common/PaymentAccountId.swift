//
//  PaymentAccountId.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

enum PaymentAccountId: Hashable {
    case tangemPay(userWalletId: UserWalletId)
    case virtualAccount(userWalletId: UserWalletId)
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension PaymentAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        switch self {
        case .tangemPay(let userWalletId):
            return "Tpay/\(userWalletId.stringValue)"
        case .virtualAccount(let userWalletId):
            return "VA/\(userWalletId.stringValue)"
        }
    }
}
