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

    func transactionStatus(_ transaction: StakingTransaction) async throws -> StakeKitTransactionParams.Status? {
        let transactionInfo = try await apiProvider.transaction(id: transaction.id)
        return StakeKitTransactionParams.Status(rawValue: transactionInfo.status)
    }
}
