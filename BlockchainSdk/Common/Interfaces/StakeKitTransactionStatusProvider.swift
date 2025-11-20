//
//  StakeKitTransactionStatusProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol StakeKitTransactionStatusProvider {
    func transactionStatus(_ transaction: StakingTransaction) async throws -> StakeKitTransactionParams.Status?
}
