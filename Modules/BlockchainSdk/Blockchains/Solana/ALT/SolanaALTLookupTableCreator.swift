//
//  SolanaALTLookupTableCreator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

protocol SolanaALTLookupTableCreator {
    /// Creates a new Address Lookup Table (ALT) and extends it with the provided account keys.
    /// - Parameters:
    ///   - accountKeys: Public keys to be added to the new ALT.
    ///   - authority: The authority public key for the ALT.
    ///   - payer: The payer public key for transaction fees.
    /// - Returns: The created AddressLookupTableAccount.
    /// - Throws: If any network or transaction error occurs.
    func createLookupTableAccounts(accountKeys: [PublicKey], authority: PublicKey, payer: PublicKey) async throws -> AddressLookupTableAccount

    /// Extends an existing Address Lookup Table (ALT) with additional public keys.
    /// - Parameters:
    ///   - lookupTableAddress: The public key of the ALT to extend.
    ///   - authority: The authority public key for the ALT.
    ///   - payer: The payer public key for transaction fees.
    ///   - addresses: Public keys to be added to the ALT.
    /// - Throws: If any network or transaction error occurs.
    func extendedLookupTableAccounts(lookupTableAddress: PublicKey, authority: PublicKey, payer: PublicKey, addresses: [PublicKey]) async throws
}

/// Responsible for creating and extending Address Lookup Tables (ALT) in the Solana blockchain.
/// Handles transaction building, signing, and sending for both creation and extension of ALT accounts.
struct SolanaCommonALTLookupTableCreator: SolanaALTLookupTableCreator {
    // MARK: - Properties

    /// Service for interacting with the Solana network (fetching blockhash, slot, sending transactions, etc.).
    private let networkService: SolanaNetworkService
    /// Transaction signer for Solana transactions.
    private let signer: SolanaTransactionSigner

    /// Initializes the ALT lookup table creator with required dependencies.
    /// - Parameters:
    ///   - networkService: Service for Solana network operations.
    ///   - signer: Transaction signer for Solana transactions.
    init(networkService: SolanaNetworkService, signer: SolanaTransactionSigner) {
        self.networkService = networkService
        self.signer = signer
    }

    // MARK: - Implementation

    func createLookupTableAccounts(
        accountKeys: [PublicKey],
        authority: PublicKey,
        payer: PublicKey
    ) async throws -> AddressLookupTableAccount {
        let recentBlockhash = try await networkService.getLatestBlockhash()
        let recentSlot = try await networkService.getSlot()

        let (transaction, address) = try buildForCreateSign(
            accountKeys: accountKeys,
            authority: authority,
            payer: payer,
            recentBlockhash: recentBlockhash,
            recentSlot: recentSlot
        )

        try await transaction.sign(signers: [signer], queue: DispatchQueue.global())

        let buildForSend = try transaction.serialize().get()

        _ = try await networkService.sendRaw(
            base64serializedTransaction: buildForSend.base64EncodedString(),
            startSendingTimestamp: Date()
        ).async()

        let lookupTableAccount = try await networkService.getAddressLookupTable(accountKey: address)

        return lookupTableAccount
    }

    func extendedLookupTableAccounts(
        lookupTableAddress: PublicKey,
        authority: PublicKey,
        payer: PublicKey,
        addresses: [PublicKey]
    ) async throws {
        let recentBlockhash = try await networkService.getLatestBlockhash()
        let recentSlot = try await networkService.getSlot()

        let buildForSend = try buildForExtendSign(
            tableAddress: lookupTableAddress,
            authority: authority,
            payer: payer,
            recentBlockhash: recentBlockhash,
            recentSlot: recentSlot,
            accountKeys: addresses
        )

        try await buildForSend.sign(signers: [signer], queue: DispatchQueue.global())

        let serializedV0 = try buildForSend.serialize().get()

        _ = try await networkService.sendRaw(
            base64serializedTransaction: serializedV0.base64EncodedString(),
            startSendingTimestamp: Date()
        ).async()

        _ = try await networkService.getAddressLookupTable(accountKey: lookupTableAddress)
    }

    // MARK: - Private Implementation

    /// Builds and signs a transaction for creating a new ALT and extending it with initial keys.
    /// - Parameters:
    ///   - accountKeys: Public keys to be added to the new ALT.
    ///   - authority: The authority public key for the ALT.
    ///   - payer: The payer public key for transaction fees.
    ///   - recentBlockhash: The latest blockhash for the transaction.
    ///   - recentSlot: The latest slot for the transaction.
    /// - Returns: A tuple containing the built transaction and the new ALT's public key.
    /// - Throws: If transaction building fails.
    private func buildForCreateSign(
        accountKeys: [PublicKey],
        authority: PublicKey,
        payer: PublicKey,
        recentBlockhash: String,
        recentSlot: UInt64
    ) throws -> (transaction: SolanaSwift.Transaction, tableAddress: PublicKey) {
        let createdLookupTableResult = try LookUpTableProgram.createLookupTable(
            authority: authority,
            payer: payer,
            recentSlot: recentSlot
        )

        let extendedLookupTableInstruction = LookUpTableProgram.extendLookupTable(
            lookupTable: createdLookupTableResult.1,
            authority: authority,
            payer: payer,
            addresses: Array(accountKeys)
        )

        let transaction = SolanaSwift.Transaction.empty(
            feePayer: payer,
            recentBlockhash: recentBlockhash
        ).add(createdLookupTableResult.0, extendedLookupTableInstruction)

        return (transaction, createdLookupTableResult.1)
    }

    /// Builds and signs a transaction for extending an existing ALT with additional keys.
    /// - Parameters:
    ///   - tableAddress: The public key of the ALT to extend.
    ///   - authority: The authority public key for the ALT.
    ///   - payer: The payer public key for transaction fees.
    ///   - recentBlockhash: The latest blockhash for the transaction.
    ///   - recentSlot: The latest slot for the transaction.
    ///   - accountKeys: Public keys to be added to the ALT.
    /// - Returns: The built transaction ready for signing and sending.
    /// - Throws: If transaction building fails.
    private func buildForExtendSign(
        tableAddress: PublicKey,
        authority: PublicKey,
        payer: PublicKey,
        recentBlockhash: String,
        recentSlot: UInt64,
        accountKeys: [PublicKey]
    ) throws -> SolanaSwift.Transaction {
        let extendedLookupTableInstruction = LookUpTableProgram.extendLookupTable(
            lookupTable: tableAddress,
            authority: authority,
            payer: payer,
            addresses: Array(accountKeys)
        )

        let transaction = SolanaSwift.Transaction.empty(
            feePayer: payer,
            recentBlockhash: recentBlockhash,
        ).add(extendedLookupTableInstruction)

        return transaction
    }
}

struct SolanaDummyALTLookupTableCreator: SolanaALTLookupTableCreator {
    private let lookupTableAccountKey: String
    private let lookupTableAccountDecodeState: Data

    init(lookupTableAccountKey: String, lookupTableAccountDecodeState: Data) {
        self.lookupTableAccountKey = lookupTableAccountKey
        self.lookupTableAccountDecodeState = lookupTableAccountDecodeState
    }

    func createLookupTableAccounts(
        accountKeys: [PublicKey],
        authority: PublicKey,
        payer: PublicKey
    ) async throws -> AddressLookupTableAccount {
        let key = PublicKey(string: lookupTableAccountKey)!
        let state = try JSONDecoder().decode(AddressLookupTableState.self, from: lookupTableAccountDecodeState)
        return AddressLookupTableAccount(key: key, state: state)
    }

    func extendedLookupTableAccounts(
        lookupTableAddress: PublicKey,
        authority: PublicKey,
        payer: PublicKey,
        addresses: [PublicKey]
    ) async throws {
        return
    }
}
