//
//  CollectiblesColdKeyTransactionSender.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct CollectiblesColdKeyTransactionSender {
    // MARK: - Properties

    private let serviceProvider: any CollectiblesChainServiceProvider

    // MARK: - Init

    public init(serviceProvider: any CollectiblesChainServiceProvider) {
        self.serviceProvider = serviceProvider
    }

    // MARK: - Methods

    func fetchLatestBlockhash() async throws -> SolanaBlockhash {
        try await serviceProvider.service().latestBlockhash()
    }

    func sign(
        _ instructions: [CollectiblesInstruction],
        coldKey: Wallet.PublicKey,
        blockhash: SolanaBlockhash,
        signer: any CollectiblesColdKeySigner
    ) async throws -> SignedTransaction {
        try await makeTransaction(instructions, feePayer: coldKey.blockchainKey, blockhash: blockhash).signed(by: signer, coldKey: coldKey)
    }

    // [REDACTED_TODO_COMMENT]
    /// `nil` when the node already held the transaction: an earlier attempt reached the chain and only its
    /// response was lost. Nothing here has to tell "seen before" apart from "applied" — the loop resolves
    /// again after every step, and a change that never landed shows up as a state that did not advance.
    func broadcast(_ signed: SignedTransaction) async throws -> String? {
        do {
            return try await serviceProvider.service().send(
                serializedTransaction: try signed.serialized(),
                startSendingTimestamp: signed.transaction.blockhashFetchedAt
            )
        } catch let sendError as SolanaSendError {
            return try signature(after: sendError)
        }
    }
}

// MARK: - Private logic

private extension CollectiblesColdKeyTransactionSender {
    func makeTransaction(
        _ instructions: [CollectiblesInstruction],
        feePayer: Data,
        blockhash: SolanaBlockhash
    ) throws -> SolanaSelfPaidTransaction {
        try serviceProvider.service().makeSelfPaidTransaction(
            instructions: instructions.map(Self.rawInstruction),
            feePayer: feePayer,
            blockhash: blockhash
        )
    }

    func signature(after sendError: SolanaSendError) throws -> String? {
        switch sendError {
        case .alreadyProcessed:
            return nil
        case .programError(let code, let logs):
            CollectiblesLogger.debug("Program rejected the transaction, code \(code)\n\(logs.joined(separator: "\n"))")
            throw CollectiblesProgramRejection(rawValue: code) ?? sendError
        }
    }

    static func rawInstruction(_ instruction: CollectiblesInstruction) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: instruction.programId,
            accounts: instruction.accounts.map {
                .init(address: $0.address, isSigner: $0.isSigner, isWritable: $0.isWritable)
            },
            data: instruction.data
        )
    }
}

// MARK: - Signed Transaction

extension CollectiblesColdKeyTransactionSender {
    struct SignedTransaction {
        let transaction: SolanaSelfPaidTransaction
        let signature: Data

        func serialized() throws -> Data {
            try transaction.serialized(signature: signature)
        }
    }
}

// MARK: - Signing

private extension SolanaSelfPaidTransaction {
    func signed(
        by signer: any CollectiblesColdKeySigner,
        coldKey: Wallet.PublicKey
    ) async throws -> CollectiblesColdKeyTransactionSender.SignedTransaction {
        let signature = try await signer.sign(message: message, coldKey: coldKey)
        return CollectiblesColdKeyTransactionSender.SignedTransaction(transaction: self, signature: signature)
    }
}
