//
//  CommonCollectiblesTransactionSender.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
import BlockchainSdk

public final class CommonCollectiblesTransactionSender {
    private let serviceProvider: any CollectiblesChainServiceProvider

    public init(serviceProvider: any CollectiblesChainServiceProvider) {
        self.serviceProvider = serviceProvider
    }
}

// MARK: - CollectiblesTransactionSender protocol conformance

extension CommonCollectiblesTransactionSender: CollectiblesTransactionSender {
    public func send(signedTransaction: Data, startSendingTimestamp: Date) async throws -> String {
        try await serviceProvider.service().send(
            serializedTransaction: signedTransaction,
            startSendingTimestamp: startSendingTimestamp
        )
    }
}
