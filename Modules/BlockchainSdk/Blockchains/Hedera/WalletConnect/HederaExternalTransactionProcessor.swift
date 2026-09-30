//
//  HederaExternalTransactionProcessor.swift
//  BlockchainSdk
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wallet-side operations of HIP-820 (WalletConnect for Hedera) that need the Hiero SDK: parsing a dApp-built
/// `TransactionList`, signing it with the account key and submitting it, signing a bare `TransactionBody`, and
/// signing a personal message. Implemented by `HederaWalletManager`; the app reaches it through `WalletModel`.
public protocol HederaExternalTransactionProcessor {
    /// Consensus node account ids this wallet is able to submit to (`hedera_getNodeAddresses`).
    var consensusNodeAccountIds: [String] { get }

    /// Decodes a base64 `TransactionList` (or a single `Transaction`) and returns what the user must see before
    /// signing. Throws when the chunks differ in anything but the node account id, or the bytes are not a Hedera
    /// transaction.
    func parseTransactionList(_ transactionList: Data) throws -> HederaExternalTransactionSummary

    /// `hedera_signAndExecuteTransaction`: signs every chunk with the account key and submits the list.
    func signAndExecute(transactionList: Data, signer: TransactionSigner) async throws -> HederaExternalTransactionResult

    /// `hedera_signTransaction`: signs a serialised `TransactionBody` and returns the serialised `SignatureMap`.
    func sign(transactionBody: Data, signer: TransactionSigner) async throws -> Data

    /// `hedera_signMessage`: signs `"\u{19}Hedera Signed Message:\n" ‖ len ‖ message` like a transaction body and
    /// returns the serialised `SignatureMap`.
    func signMessage(_ message: String, signer: TransactionSigner) async throws -> Data
}

/// Human-readable content of a dApp-built transaction, derived from the bytes that get signed.
public struct HederaExternalTransactionSummary: Equatable {
    public struct HbarTransfer: Equatable {
        public let accountId: String
        /// Signed; negative for the sender.
        public let tinybars: Int64

        public init(accountId: String, tinybars: Int64) {
            self.accountId = accountId
            self.tinybars = tinybars
        }
    }

    public struct TokenTransfer: Equatable {
        public let tokenId: String
        public let accountId: String
        /// In the token's smallest unit; negative for the sender.
        public let amount: Int64

        public init(tokenId: String, accountId: String, amount: Int64) {
            self.tokenId = tokenId
            self.accountId = accountId
            self.amount = amount
        }
    }

    /// Hiero transaction type, e.g. `TransferTransaction`, `ContractExecuteTransaction`, `TokenAssociateTransaction`.
    public let transactionType: String
    /// Account paying the fee (`transactionId.accountId`).
    public let payerAccountId: String?
    public let transactionId: String?
    public let nodeAccountIds: [String]
    public let memo: String
    public let maxFeeTinybars: Int64?
    public let hbarTransfers: [HbarTransfer]
    public let tokenTransfers: [TokenTransfer]

    public init(
        transactionType: String,
        payerAccountId: String?,
        transactionId: String?,
        nodeAccountIds: [String],
        memo: String,
        maxFeeTinybars: Int64?,
        hbarTransfers: [HbarTransfer],
        tokenTransfers: [TokenTransfer]
    ) {
        self.transactionType = transactionType
        self.payerAccountId = payerAccountId
        self.transactionId = transactionId
        self.nodeAccountIds = nodeAccountIds
        self.memo = memo
        self.maxFeeTinybars = maxFeeTinybars
        self.hbarTransfers = hbarTransfers
        self.tokenTransfers = tokenTransfers
    }
}

/// `hedera_signAndExecuteTransaction` result fields.
public struct HederaExternalTransactionResult: Equatable {
    public let nodeId: String
    /// Hex, no prefix.
    public let transactionHash: String
    /// `<payer>@<seconds>.<nanos>`.
    public let transactionId: String

    public init(nodeId: String, transactionHash: String, transactionId: String) {
        self.nodeId = nodeId
        self.transactionHash = transactionHash
        self.transactionId = transactionId
    }
}

public enum HederaExternalTransactionError: LocalizedError, Equatable {
    case invalidTransactionList(String)
    case invalidTransactionBody
    case unsupportedCurve

    public var errorDescription: String? {
        switch self {
        case .invalidTransactionList(let reason): "The data is not a valid Hedera transaction list: \(reason)"
        case .invalidTransactionBody: "The data is not a valid Hedera transaction body."
        case .unsupportedCurve: "The account key type cannot sign Hedera transactions."
        }
    }
}
