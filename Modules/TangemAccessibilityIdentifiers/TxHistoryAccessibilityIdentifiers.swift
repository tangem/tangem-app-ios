//
//  TxHistoryAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TxHistoryAccessibilityIdentifiers {
    public static func transactionItem(key: String) -> String {
        "txHistoryTransactionItem_\(key)"
    }

    public static func transactionAmount(key: String) -> String {
        "txHistoryTransactionAmount_\(key)"
    }

    public static func transactionCurrency(key: String) -> String {
        "txHistoryTransactionCurrency_\(key)"
    }

    public static func transactionConfirmedStatus(key: String) -> String {
        "txHistoryTransactionConfirmedStatus_\(key)"
    }
}
