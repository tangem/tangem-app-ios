//
//  ExpressDestinationNotificationProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol ExpressRequiredMemoValidator {
    func isMemoRequired(destination: String, transactionParams: TransactionParams?) async -> Bool
}

struct BSDKExpressRequiredMemoValidator: ExpressRequiredMemoValidator {
    let requiredMemoRestrictable: (any RequiredMemoRestrictable)?

    func isMemoRequired(destination: String, transactionParams: TransactionParams?) async -> Bool {
        guard let requiredMemoRestrictable else {
            return false
        }

        do {
            try await requiredMemoRestrictable.validateRequiredMemo(destination: destination, transactionParams: transactionParams)
            return false
        } catch ValidationError.destinationMemoRequired {
            return true
        } catch {
            return false
        }
    }
}
