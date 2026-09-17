//
//  SolanaSponsoredTransactionService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import TangemFoundation

/// Chain access for sponsor-built transaction flows: the backend assembles the transaction and pays its fee,
/// so the app only reads program account state and broadcasts bytes that are already fully signed.
public final class SolanaSponsoredTransactionService {
    private let networkService: SolanaNetworkService

    public init(blockchain: Blockchain, walletNetworkServiceFactory: WalletNetworkServiceFactory) throws {
        networkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
    }

    /// `nil` means no account exists at the address.
    public func account(address: String) async throws -> SolanaRawAccount? {
        try await networkService.rawAccountInfo(address: address)
    }

    /// Broadcasts fully signed transaction bytes and returns the signature.
    /// - Parameter startSendingTimestamp: when the transaction's blockhash was issued. The RPC layer sleeps
    ///   the calling thread in one-second steps until 15 seconds have passed since this moment, so an older
    ///   blockhash shortens the wait and only one past 15 seconds removes it. A sponsor-issued blockhash is
    ///   fresh, so a send through here idles for most of those 15 seconds.
    public func send(serializedTransaction: Data, startSendingTimestamp: Date) async throws -> String {
        try await broadcast(
            base64SerializedTransaction: serializedTransaction.base64EncodedString(),
            startSendingTimestamp: startSendingTimestamp
        )
    }

    func broadcast(base64SerializedTransaction: String, startSendingTimestamp: Date) async throws -> String {
        do {
            return try await networkService.sendRaw(
                base64serializedTransaction: base64SerializedTransaction,
                startSendingTimestamp: startSendingTimestamp
            ).async()
        } catch {
            throw Self.sendError(from: error)
        }
    }

    /// The devnet testing path until the sponsor endpoint exists: the payer must hold enough SOL for the fee
    /// and any rent the instructions allocate. Single signer only.
    public func sendSelfPaid(
        instructions: [SolanaRawInstruction],
        feePayer: Data,
        sign: (Data) async throws -> Data
    ) async throws -> String {
        guard let feePayerKey = PublicKey(data: feePayer), feePayer.count == PublicKey.LENGTH else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        let blockhashFetchedAt = Date()
        let blockhash = try await networkService.getLatestBlockhash()

        let transaction = SolanaSwift.Transaction.empty(feePayer: feePayerKey, recentBlockhash: blockhash)
        for instruction in instructions {
            _ = transaction.add(try instruction.transactionInstruction())
        }

        // Compiling is a pure function of the instructions, the payer and the blockhash, so the bytes handed
        // out here are the same ones `serialize` signs off on — nothing may touch the transaction in between
        let message = try transaction.serializeMessage().get()
        let signature = try await sign(message)

        try transaction.addSignature(.init(signature: signature, publicKey: feePayerKey)).get()

        let serializedTransaction = try transaction.serialize().get()

        return try await broadcast(
            base64SerializedTransaction: serializedTransaction.base64EncodedString(),
            startSendingTimestamp: blockhashFetchedAt
        )
    }
}

/// An on-chain account as `getAccountInfo` returns it, before any layout is imposed.
public struct SolanaRawAccount: Sendable {
    /// Base58 id of the program that owns the account.
    public let owner: String
    public let data: Data
}

/// A program instruction in plain values, for callers that must not link SolanaSwift themselves.
public struct SolanaRawInstruction: Sendable {
    public struct AccountMeta: Sendable {
        public let address: String
        public let isSigner: Bool
        public let isWritable: Bool

        public init(address: String, isSigner: Bool, isWritable: Bool) {
            self.address = address
            self.isSigner = isSigner
            self.isWritable = isWritable
        }
    }

    /// Base58 program id.
    public let programId: String

    /// In the exact order the program declares.
    public let accounts: [AccountMeta]

    public let data: Data

    public init(programId: String, accounts: [AccountMeta], data: Data) {
        self.programId = programId
        self.accounts = accounts
        self.data = data
    }

    fileprivate func transactionInstruction() throws -> TransactionInstruction {
        guard let programIdKey = PublicKey(string: programId) else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        let keys = try accounts.map { meta -> SolanaSwift.Account.Meta in
            guard let key = PublicKey(string: meta.address) else {
                throw BlockchainSdkError.failedToConvertPublicKey
            }

            return .init(publicKey: key, isSigner: meta.isSigner, isWritable: meta.isWritable)
        }

        return TransactionInstruction(keys: keys, programId: programIdKey, data: [UInt8](data))
    }
}

/// Keeps every byte of the account data for the caller to parse.
struct SolanaRawAccountData: BufferLayout {
    static let BUFFER_LENGTH: UInt64 = 0

    let data: Data

    init(from reader: inout BinaryReader) throws {
        data = Data(try reader.readAll())
    }

    func serialize(to writer: inout Data) throws {}
}
