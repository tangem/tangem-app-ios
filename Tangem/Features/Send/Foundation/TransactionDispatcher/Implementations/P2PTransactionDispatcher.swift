//
//  P2PTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

final class P2PTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let apiProvider: P2PAPIProvider

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        apiProvider: P2PAPIProvider
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.apiProvider = apiProvider
    }
}

extension P2PTransactionDispatcher: TransactionDispatcher {
    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        <#code#>
    }
}
