//
//  TransactionHistorySyncMetadataUserWalletIDHasher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum TransactionHistorySyncMetadataUserWalletIDHasher {
    static func hash(_ userWalletId: UserWalletId) -> String {
        return userWalletId.hashedStringValue(message: Constants.message)
    }
}

// MARK: - Constants

private extension TransactionHistorySyncMetadataUserWalletIDHasher {
    enum Constants {
        static let message = "com.tangem.transactionHistory.syncMetadata"
    }
}
