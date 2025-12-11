//
//  CommonStakeKitTransactionStatusProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

final class CommonStakeKitTransactionStatusProvider: StakeKitTransactionStatusProvider {
    private let apiProvider: StakeKitAPIProvider

    init(apiProvider: StakeKitAPIProvider) {
        self.apiProvider = apiProvider
    }

    func transactionStatus(_ transaction: StakeKitTransaction) async throws -> StakeKitTransaction.Status? {
        let transactionInfo = try await apiProvider.transaction(id: transaction.id)
        return (transactionInfo.metadata as? StakeKitTransactionMetadata)
            .flatMap { StakeKitTransaction.Status(rawValue: $0.status) }
    }
}
