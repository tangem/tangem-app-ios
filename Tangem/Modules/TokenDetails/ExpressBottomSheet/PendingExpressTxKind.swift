//
//  PendingExpressTxKind.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum PendingExpressTxKind {
    case exchange
    case transaction

    var title: String {
        switch self {
        case .exchange:
            Localization.expressExchangeStatusTitle
        case .transaction:
            // [REDACTED_TODO_COMMENT]
            "Transaction status"
        }
    }

    func statusTitle(providerName: String) -> String {
        switch self {
        case .exchange:
            Localization.expressExchangeBy(providerName)
        case .transaction:
            // [REDACTED_TODO_COMMENT]
            "Transaction status"
        }
    }
}
