//
//  WalletConnectBtcTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectBtcTransaction: Codable {
    let account: String
    let recipientAddress: String
    let amount: String
    let changeAddress: String?

    var description: String {
        return """
        account: \(account),
        recipientAddress: \(recipientAddress),
        amount: \(amount),
        changeAddress: \(changeAddress ?? "not specified")
        """
    }
}
