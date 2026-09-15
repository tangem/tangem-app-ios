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
}

/// An on-chain account as `getAccountInfo` returns it, before any layout is imposed.
public struct SolanaRawAccount: Sendable {
    /// Base58 id of the program that owns the account.
    public let owner: String
    public let data: Data
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
