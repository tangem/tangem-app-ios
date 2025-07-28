//
//  SolanaALTLegacyTransactionSender.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaALTLegacyTransactionSender {
    // MARK: - Properties

    private let walletPublicKey: PublicKey
    private let accountKeysSplitProvider: SolanaAccountKeysSplitProvider
    private let sendBuilder: SolanaALTSendTransactionBuilder
    private let blockhashProvider: SolanaALTBlockhashProvider
    private let lookupTableCreator: SolanaALTLookupTableCreator

    // MARK: - Init

    init(
        walletPublicKey: PublicKey,
        accountKeysSplitProvider: SolanaAccountKeysSplitProvider,
        sendBuilder: SolanaALTSendTransactionBuilder,
        blockhashProvider: SolanaALTBlockhashProvider,
        lookupTableCreator: SolanaALTLookupTableCreator
    ) {
        self.walletPublicKey = walletPublicKey
        self.accountKeysSplitProvider = accountKeysSplitProvider
        self.sendBuilder = sendBuilder
        self.blockhashProvider = blockhashProvider
        self.lookupTableCreator = lookupTableCreator
    }

    // MARK: - Implementation

    /// Sends a legacy Solana transaction using ALT (Address Lookup Table) mechanism.
    /// - Parameter message: The legacy message to send.
    /// - Returns: The transaction ID as a string.
    /// - Throws: An error if sending fails at any step.
    @discardableResult
    mutating func buildForSend(message: LegacyMessage) async throws -> String {
        let (staticAccountKeys, altKeys) = accountKeysSplitProvider.splitStaticAccountKeys(legacy: message)

        let addressLookupTableAccounts = try await lookupTableCreator.createLookupTableAccounts(
            accountKeys: staticAccountKeys.map { $0.0 },
            authority: walletPublicKey,
            payer: walletPublicKey
        )

        BSDKLogger.debug("ALT: Created lookup table account with key: \(addressLookupTableAccounts.key.base58EncodedString)")

        let instructions = try buildV0TransactionInstructions(
            legacyMessage: message,
            staticAccountKeys: staticAccountKeys.map { $0.0 },
            altKeys: altKeys
        )

        let newRecentBlockhash = try await blockhashProvider.provideBlockhash()
        BSDKLogger.debug("ALT: Updated latest blockhash for send transaction Base64: \(newRecentBlockhash)")

        let messageV0 = try MessageV0.compile(
            payerKey: walletPublicKey,
            instructions: instructions,
            recentBlockHash: newRecentBlockhash,
            addressLookupTableAccounts: [addressLookupTableAccounts]
        )

        let buildForSend = try await sendBuilder.buildForSend(message: messageV0)

        return buildForSend.base64EncodedString()
    }

    // MARK: - Private Implementation

    /// Builds an array of TransactionInstruction for v0 from a legacy message, static, and alt keys.
    /// - Parameters:
    ///   - legacyMessage: The legacy message containing instructions and account keys.
    ///   - staticAccountKeys: The static account keys for the v0 message.
    ///   - altKeys: The alternative (ALT) keys for the v0 message.
    /// - Returns: An array of TransactionInstruction objects for the v0 transaction.
    private func buildV0TransactionInstructions(
        legacyMessage: LegacyMessage,
        staticAccountKeys: [PublicKey],
        altKeys: [PublicKey]
    ) throws -> [TransactionInstruction] {
        return legacyMessage.instructions.map { instr in
            let keys: [Account.Meta] = instr.accounts.map { idx in
                let key = legacyMessage.accountKeys[idx]
                return Account.Meta(
                    publicKey: key,
                    isSigner: legacyMessage.isAccountSigner(index: idx),
                    isWritable: legacyMessage.isAccountWritable(index: idx)
                )
            }
            let programIdKey = legacyMessage.accountKeys[Int(instr.programIdIndex)]
            return TransactionInstruction(
                keys: keys,
                programId: programIdKey,
                data: instr.data
            )
        }
    }
}
