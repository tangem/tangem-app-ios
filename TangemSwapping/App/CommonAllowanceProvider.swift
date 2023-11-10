//
//  CommonAllowanceProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonAllowanceProvider {
    private let allowanceLimit: ThreadSafeContainer<[ExpressCurrency: Decimal]> = [:]
    // Cached addresses for check approving transactions
    private let pendingTransactions: ThreadSafeContainer<[ExpressCurrency: PendingTransactionState]> = [:]
}

extension CommonAllowanceProvider {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}

