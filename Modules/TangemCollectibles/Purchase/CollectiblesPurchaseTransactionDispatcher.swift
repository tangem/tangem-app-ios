//
//  CollectiblesPurchaseTransactionDispatcher.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SolanaSwift

public struct CollectiblesPurchaseTransactionDispatcher {
    // MARK: - Properties

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let configReader: any CollectiblesConfigReader
    private let sessionKeySigner: any CollectiblesSessionKeySigner
    private let transactionSender: CollectiblesColdKeyTransactionSender

    // MARK: - Init

    public init(
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        configReader: any CollectiblesConfigReader,
        sessionKeySigner: any CollectiblesSessionKeySigner,
        transactionSender: CollectiblesColdKeyTransactionSender
    ) {
        self.coldOwnerProvider = coldOwnerProvider
        self.configReader = configReader
        self.sessionKeySigner = sessionKeySigner
        self.transactionSender = transactionSender
    }

    // MARK: - Methods

    func sign(
        _ purchase: CollectiblesPackPurchase,
        vault: CollectiblesVaultInfo
    ) async throws -> CollectiblesSignedPurchase {
        let coldOwner = try coldOwnerProvider.requiredColdOwnerKey().blockchainKey
        let config = try await configReader.configInfo()

        try validate(purchase, vault: vault, config: config)

        let sessionKey = vault.sessionKey
        let chainMemo = purchase.memo + Constants.chainMemoSuffix
        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let instructions = [
            Self.memoInstruction(chainMemo),
            try program.purchasePackInstruction(
                coldOwner: coldOwner,
                sessionKey: sessionKey,
                config: config,
                amount: purchase.amount,
                feeAmount: purchase.feeAmount,
                memo: chainMemo
            ),
        ]

        // [REDACTED_TODO_COMMENT]
        let signed = try await transactionSender.sign(
            instructions,
            feePayer: sessionKey,
            blockhash: try await transactionSender.fetchLatestBlockhash(),
            signer: sessionKeySigner.signSpin
        )

        return CollectiblesSignedPurchase(
            signature: signed.signature.base58EncodedString,
            amount: purchase.amount,
            feeAmount: purchase.feeAmount,
            serializedTransaction: try signed.serialized(),
            blockhashFetchedAt: signed.transaction.blockhashFetchedAt
        )
    }

    func validate(_ purchase: CollectiblesPackPurchase, against confirmedPrice: CollectiblesConfirmedPrice) throws {
        guard purchase.amount == confirmedPrice.amount else {
            throw ValidationError.amountMismatch
        }

        guard purchase.feeAmount <= confirmedPrice.feeAmount else {
            throw ValidationError.feeAboveConfirmed
        }
    }

    func send(_ signedPurchase: CollectiblesSignedPurchase) async throws(CollectiblesSendError) {
        CollectiblesLogger.debug("purchase: sending purchase_pack, signature=\(signedPurchase.signature)")
        do {
            _ = try await transactionSender.broadcast(
                serializedTransaction: signedPurchase.serializedTransaction,
                startSendingTimestamp: signedPurchase.blockhashFetchedAt
            )
        } catch {
            let sendError = CollectiblesSendError(
                classifying: error,
                blockhashFetchedAt: signedPurchase.blockhashFetchedAt
            )

            if case .outcomeUnknown = sendError {
                CollectiblesLogger.error("purchase: purchase_pack outcome unknown", error: error)
            }

            throw sendError
        }
        CollectiblesLogger.debug("purchase: purchase_pack sent")
    }
}

// MARK: - Private logic

private extension CollectiblesPurchaseTransactionDispatcher {
    func validate(
        _ purchase: CollectiblesPackPurchase,
        vault: CollectiblesVaultInfo,
        config: CollectiblesConfigInfo
    ) throws {
        guard purchase.usdcMint == config.usdcMint.base58EncodedString else {
            throw ValidationError.mintMismatch
        }

        let spending = CollectiblesVaultProgram.SpendingMath.self

        guard spending.fitsFeeCorridor(amount: purchase.amount, feeAmount: purchase.feeAmount, config: config) else {
            throw ValidationError.feeOutsideCorridor
        }

        let now = Date()
        let fitsCaps = spending.fitsCaps(amount: purchase.amount, feeAmount: purchase.feeAmount, vault: vault, now: now)

        guard fitsCaps else {
            throw ValidationError.exceedsLimits
        }
    }

    static func memoInstruction(_ memo: String) -> CollectiblesInstruction {
        CollectiblesInstruction(programId: Constants.memoProgramId, accounts: [], data: Data(memo.utf8))
    }
}

// MARK: - Error

private extension CollectiblesPurchaseTransactionDispatcher {
    enum ValidationError: Error {
        case mintMismatch
        case amountMismatch
        case feeAboveConfirmed
        case feeOutsideCorridor
        case exceedsLimits
    }
}

// MARK: - Constants

private extension CollectiblesPurchaseTransactionDispatcher {
    enum Constants {
        static let chainMemoSuffix = ":open"
        static let memoProgramId = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"
    }
}
