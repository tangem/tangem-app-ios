//
//  WalletConnectTronSignTransactionDTO.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct Commons.AnyCodable

/// Wire shapes of `tron_signTransaction` (https://docs.reown.com/advanced/multichain/rpc-reference/tron-rpc).
///
/// Two request layouts exist: the legacy one nests the transaction twice (`transaction.transaction`), the
/// `tron_method_version: "v1"` one does not. Both are accepted. Everything the wallet signs and shows is derived
/// from `raw_data_hex`; the JSON `raw_data` is only echoed back to the dApp untouched.
enum WalletConnectTronSignTransactionDTO {
    struct Request: Codable {
        let address: String
        let transaction: TransactionEnvelope

        /// The transaction object, whichever layout the dApp used.
        var unsignedTransaction: UnsignedTransaction {
            transaction.transaction ?? transaction.unsigned
        }
    }

    /// Either an `UnsignedTransaction` directly (v1) or `{ "transaction": UnsignedTransaction }` (legacy).
    struct TransactionEnvelope: Codable {
        let transaction: UnsignedTransaction?
        let unsigned: UnsignedTransaction

        private enum CodingKeys: String, CodingKey {
            case transaction
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let nested = try container.decodeIfPresent(UnsignedTransaction.self, forKey: .transaction) {
                transaction = nested
                unsigned = nested
            } else {
                transaction = nil
                unsigned = try UnsignedTransaction(from: decoder)
            }
        }

        /// Re-encodes in the v1 (flat) layout; only used for logging and tests.
        func encode(to encoder: any Encoder) throws {
            try unsigned.encode(to: encoder)
        }
    }

    struct UnsignedTransaction: Codable {
        /// Hex of the serialised `protocol.Transaction.raw` — the bytes whose sha256 is signed.
        let rawDataHex: String
        /// sha256(raw_data_hex) if the dApp included it; verified against our own computation.
        let txID: String?
        let visible: Bool?
        /// Opaque copy of the dApp's JSON `raw_data`, returned as-is in the response.
        let rawData: AnyCodable?

        private enum CodingKeys: String, CodingKey {
            case rawDataHex = "raw_data_hex"
            case txID
            case visible
            case rawData = "raw_data"
        }
    }

    /// Response shape — the transaction the dApp sent plus `signature`.
    struct Response: Codable {
        let txID: String
        let signature: [String]
        let rawData: AnyCodable?
        let rawDataHex: String
        let visible: Bool

        private enum CodingKeys: String, CodingKey {
            case txID
            case signature
            case rawData = "raw_data"
            case rawDataHex = "raw_data_hex"
            case visible
        }
    }

    /// What the wallet actually signs, decoded from `raw_data_hex` and shown in the request details.
    struct ParsedTransaction: Codable, Equatable {
        enum Kind: String, Codable {
            case transfer
            case contractCall
        }

        let kind: Kind
        let ownerAddress: String
        /// Destination for a transfer, contract for a call.
        let targetAddress: String
        /// In sun (1 TRX = 1_000_000 sun).
        let amountSun: Int64
        /// ABI calldata of a contract call, hex.
        let callData: String?
        /// In sun; `nil` when the transaction sets none.
        let feeLimitSun: Int64?
        let memo: String?
        let txID: String
    }
}
