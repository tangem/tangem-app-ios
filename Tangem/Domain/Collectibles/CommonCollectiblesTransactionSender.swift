//
//  CommonCollectiblesTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonCollectiblesTransactionSender {
    private let serviceProvider: CollectiblesChainServiceProvider

    init(serviceProvider: CollectiblesChainServiceProvider = CollectiblesChainServiceProvider()) {
        self.serviceProvider = serviceProvider
    }
}

// MARK: - CollectiblesTransactionSender protocol conformance

extension CommonCollectiblesTransactionSender: CollectiblesTransactionSender {
    func send(signedTransaction: Data, startSendingTimestamp: Date) async throws -> String {
        try await serviceProvider.service().send(
            serializedTransaction: signedTransaction,
            startSendingTimestamp: startSendingTimestamp
        )
    }
}
