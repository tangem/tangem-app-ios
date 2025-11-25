//
//  StakingTransactionSender+P2P.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension StakingTransactionSender where Self: WalletProvider, Self: P2PTransactionDataProvider {
    func sendP2P(
        transaction: P2PTransaction,
        signer: TransactionSigner,
        executeSend: @escaping (String) async throws -> String
    ) async throws -> TransactionSendResult {
        let hashToSign = try prepareDataForSign(transaction: transaction)

        let signature = try await signer.sign(
            hash: hashToSign,
            walletPublicKey: wallet.publicKey
        ).async()

        let rawTransaction = try prepareDataForSend(transaction: transaction, signature: signature)
        let hash = try await executeSend(rawTransaction)

        return TransactionSendResult(hash: hash, currentProviderHost: .empty)
    }
}
