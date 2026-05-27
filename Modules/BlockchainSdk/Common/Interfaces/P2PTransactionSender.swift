//
//  P2PTransactionSender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol P2PTransactionSender {
    /// Prepares and sends p2p transactions
    func sendP2P(
        transactions: [P2PTransaction],
        signer: TransactionSigner,
        executeSend: @escaping ([String]) async throws -> [(Int, String)]
    ) async throws -> [TransactionSendResult]
}
