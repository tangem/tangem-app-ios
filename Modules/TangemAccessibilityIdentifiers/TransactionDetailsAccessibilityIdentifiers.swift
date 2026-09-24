//
//  TransactionDetailsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionDetailsAccessibilityIdentifiers {
    public static let sheet = "transactionDetailsSheet"

    public static func infoRow(id: String) -> String {
        "transactionDetailsInfoRow_\(id)"
    }
}
