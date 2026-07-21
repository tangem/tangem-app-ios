//
//  StakeKitTransactionStatusProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol StakeKitTransactionStatusProvider {
    func transactionStatus(_ transaction: StakeKitTransaction) async throws -> StakeKitTransaction.Status?
}
