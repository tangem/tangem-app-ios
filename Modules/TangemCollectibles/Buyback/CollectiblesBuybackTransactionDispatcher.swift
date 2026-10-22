//
//  CollectiblesBuybackTransactionDispatcher.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SolanaSwift

public struct CollectiblesBuybackTransactionDispatcher {
    // MARK: - Properties

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let configReader: any CollectiblesConfigReader
    private let coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory
    private let transactionSender: CollectiblesColdKeyTransactionSender
    private let transactionHelper = SolanaTransactionHelper()

    // MARK: - Init

    public init(
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        configReader: any CollectiblesConfigReader,
        coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory,
        transactionSender: CollectiblesColdKeyTransactionSender
    ) {
        self.coldOwnerProvider = coldOwnerProvider
        self.configReader = configReader
        self.coldKeyInteractorFactory = coldKeyInteractorFactory
        self.transactionSender = transactionSender
    }

    // MARK: - Methods

    func sign(_ preparedTransaction: Data, terms: CollectiblesBuybackTerms) async throws -> CollectiblesSignedBuyback {
        let receivedAt = Date()
        let coldKey = try coldOwnerProvider.requiredColdOwnerKey()
        let prepared = try CollectiblesPreparedTransaction(serialized: preparedTransaction)
        let config = try await configReader.configInfo()
        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let payoutAccount = try program.vaultUsdcAddress(coldOwner: coldKey.blockchainKey, usdcMint: config.usdcMint)

        let verifier = CollectiblesBuybackTransactionVerifier(
            owner: coldKey.blockchainKey,
            usdcMint: config.usdcMint,
            payoutAccount: payoutAccount,
            terms: terms
        )
        try verifier.verify(prepared)

        let signature = try await coldKeyInteractorFactory
            .makeInteractor()
            .sign(message: prepared.message, coldKey: coldKey)
        let signedTransaction = try transactionHelper.putSignature(
            signature,
            publicKey: coldKey.blockchainKey,
            transaction: preparedTransaction
        )

        return CollectiblesSignedBuyback(
            signature: prepared.transactionID.base58EncodedString,
            serializedTransaction: signedTransaction,
            receivedAt: receivedAt
        )
    }

    func send(_ signedBuyback: CollectiblesSignedBuyback) async throws(CollectiblesSendError) {
        CollectiblesLogger.debug("buyback: sending, signature=\(signedBuyback.signature)")
        do {
            _ = try await transactionSender.broadcast(
                serializedTransaction: signedBuyback.serializedTransaction,
                startSendingTimestamp: Constants.unthrottledSendTimestamp
            )
        } catch {
            let sendError = CollectiblesSendError(classifying: error, blockhashFetchedAt: signedBuyback.receivedAt)

            if case .outcomeUnknown = sendError {
                CollectiblesLogger.error("buyback: outcome unknown", error: error)
            }

            throw sendError
        }
        CollectiblesLogger.debug("buyback: sent")
    }
}

// MARK: - Constants

private extension CollectiblesBuybackTransactionDispatcher {
    enum Constants {
        static let unthrottledSendTimestamp = Date.distantPast
    }
}
