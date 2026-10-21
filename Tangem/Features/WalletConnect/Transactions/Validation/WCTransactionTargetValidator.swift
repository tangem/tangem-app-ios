//
//  WCTransactionTargetValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WCTransactionTargetValidator {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    static func transaction(method: WalletConnectMethod, requestData: Data) -> WalletConnectEthTransaction? {
        switch method {
        case .sendTransaction, .signTransaction:
            return try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: requestData)
        default:
            return nil
        }
    }

    func validateChain(of transaction: WalletConnectEthTransaction) -> [WCNotificationEvent] {
        guard
            let declaredChainId = transaction.declaredChainId,
            let chainId = blockchain.chainId,
            declaredChainId != chainId
        else {
            return []
        }

        WCLogger.warning("Transaction declares chain ID \(declaredChainId) but was requested on \(blockchain.displayName) (chain ID \(chainId))")

        return [.chainMismatch(blockchainName: blockchain.displayName, declaredChainId: declaredChainId)]
    }

    func validateRecipient(
        of transaction: WalletConnectEthTransaction,
        hasCode: (String) async throws -> Bool
    ) async -> [WCNotificationEvent] {
        guard transaction.carriesCallData else {
            return []
        }

        do {
            let recipientHasCode = try await hasCode(transaction.to)
            WCLogger.info("Recipient \(transaction.to) on \(blockchain.displayName) has code: \(recipientHasCode)")

            return recipientHasCode ? [] : [.recipientIsNotContract(blockchainName: blockchain.displayName)]
        } catch {
            WCLogger.error("Failed to check the code at \(transaction.to) on \(blockchain.displayName)", error: error)
            return []
        }
    }
}
