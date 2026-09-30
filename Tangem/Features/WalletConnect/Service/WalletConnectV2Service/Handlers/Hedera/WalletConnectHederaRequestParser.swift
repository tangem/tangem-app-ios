//
//  WalletConnectHederaRequestParser.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Pure, testable parts of the Hedera (HIP-820) WalletConnect handlers.
enum WalletConnectHederaRequestParser {
    /// Upper bound on a base64-decoded `TransactionList` / `TransactionBody` accepted from a dApp
    /// (the network caps a transaction at 6 KiB; a list carries one copy per node).
    static let maxTransactionByteCount = 256 * 1024

    /// `hedera:<network>:<shard>.<realm>.<num>[-<checksum>]` (HIP-30).
    struct SignerAccountId: Equatable {
        let network: String
        /// `<shard>.<realm>.<num>` without checksum.
        let accountId: String
    }

    static func parseSignerAccountId(_ raw: String) throws -> SignerAccountId {
        let parts = raw.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].lowercased() == WalletConnectSupportedNamespace.hedera.rawValue else {
            throw WalletConnectHederaRequestError.invalidSignerAccountId
        }

        let network = parts[1].lowercased()
        let accountId = parts[2].split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)[0]
        let idParts = accountId.split(separator: ".", omittingEmptySubsequences: false)
        guard !network.isEmpty, idParts.count == 3, idParts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else {
            throw WalletConnectHederaRequestError.invalidSignerAccountId
        }

        return SignerAccountId(network: network, accountId: String(accountId))
    }

    /// The signer the dApp named must be the account WalletConnect resolved, on the network of the request.
    static func validateSigner(_ signer: SignerAccountId, accountId: String, blockchain: Blockchain) throws {
        guard blockchain.wcChainID?.contains(signer.network) == true else {
            throw WalletConnectHederaRequestError.networkMismatch(signer.network)
        }
        guard signer.accountId == accountId else {
            throw WalletConnectHederaRequestError.signerMismatch
        }
    }

    /// Standard base64 with a size bound.
    static func decodeTransactionBytes(_ base64: String, field: String) throws -> Data {
        guard let data = Data(base64Encoded: base64), !data.isEmpty else {
            throw WalletConnectHederaRequestError.invalidBase64(field)
        }
        guard data.count <= maxTransactionByteCount else {
            throw WalletConnectHederaRequestError.tooLarge(field)
        }
        return data
    }
}

enum WalletConnectHederaRequestError: LocalizedError, Equatable {
    case invalidSignerAccountId
    case networkMismatch(String)
    case signerMismatch
    case invalidBase64(String)
    case tooLarge(String)
    case processorUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidSignerAccountId:
            "signerAccountId must be hedera:<network>:<shard>.<realm>.<num>"
        case .networkMismatch(let network):
            "signerAccountId network \(network) does not match the request chain"
        case .signerMismatch:
            "signerAccountId is not the connected account"
        case .invalidBase64(let field):
            "\(field) is not valid base64"
        case .tooLarge(let field):
            "\(field) exceeds \(WalletConnectHederaRequestParser.maxTransactionByteCount) bytes"
        case .processorUnavailable:
            "Hedera transaction processing is unavailable for this account"
        }
    }
}

/// Codable projection of `HederaExternalTransactionSummary` used as `requestData` for the details sheet.
struct WalletConnectHederaTransactionDetails: Codable, Equatable {
    struct Transfer: Codable, Equatable {
        let account: String
        let amount: Int64
        let tokenId: String?
    }

    let transactionType: String
    let payerAccountId: String?
    let transactionId: String?
    let nodeAccountIds: [String]
    let memo: String
    let maxFeeTinybars: Int64?
    let hbarTransfers: [Transfer]
    let tokenTransfers: [Transfer]

    init(_ summary: HederaExternalTransactionSummary) {
        transactionType = summary.transactionType
        payerAccountId = summary.payerAccountId
        transactionId = summary.transactionId
        nodeAccountIds = summary.nodeAccountIds
        memo = summary.memo
        maxFeeTinybars = summary.maxFeeTinybars
        hbarTransfers = summary.hbarTransfers.map { Transfer(account: $0.accountId, amount: $0.tinybars, tokenId: nil) }
        tokenTransfers = summary.tokenTransfers.map { Transfer(account: $0.accountId, amount: $0.amount, tokenId: $0.tokenId) }
    }
}
