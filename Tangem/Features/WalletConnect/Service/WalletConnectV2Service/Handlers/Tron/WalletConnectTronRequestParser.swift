//
//  WalletConnectTronRequestParser.swift
//  Tangem
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import BlockchainSdk
import TangemSdk
import TangemFoundation

/// Pure, testable parts of the Tron WalletConnect handlers: request → bytes to sign, and signature formatting.
enum WalletConnectTronRequestParser {
    /// Upper bound on a serialised `Transaction.raw` accepted from a dApp (node limit is 500 KiB; a wallet
    /// transaction is a few hundred bytes).
    static let maxRawDataByteCount = 64 * 1024

    struct SignableTransaction: Equatable {
        /// Serialised `protocol.Transaction.raw`.
        let rawData: Data
        /// sha256(rawData) — both the signing digest and the txID.
        let hash: Data
        let parsed: WalletConnectTronSignTransactionDTO.ParsedTransaction
    }

    /// Decodes `raw_data_hex`, checks it against the dApp's `txID`, parses the single contract it carries and
    /// verifies the connected account is its owner.
    static func makeSignableTransaction(
        from transaction: WalletConnectTronSignTransactionDTO.UnsignedTransaction,
        expectedOwnerAddress: String
    ) throws -> SignableTransaction {
        let rawData = Data(hexString: transaction.rawDataHex.removeHexPrefix())
        guard !rawData.isEmpty, rawData.count <= maxRawDataByteCount else {
            throw WalletConnectTronRequestError.invalidRawData
        }

        let hash = rawData.sha256()

        // A txID that does not match the bytes means the dApp is showing the user one transaction and asking
        // the wallet to sign another; refuse rather than pick a side.
        if let txID = transaction.txID, txID.removeHexPrefix().lowercased() != hash.hexString.lowercased() {
            throw WalletConnectTronRequestError.txIDMismatch
        }

        let parsed: TronRawTransactionParser.ParsedTransaction
        do {
            parsed = try TronRawTransactionParser().parse(rawTransaction: rawData)
        } catch let error as TronRawTransactionParserError {
            throw WalletConnectTronRequestError.unsupportedTransaction(error.rawValue)
        }

        let details: WalletConnectTronSignTransactionDTO.ParsedTransaction
        switch parsed {
        case .transfer(let transfer):
            details = .init(
                kind: .transfer,
                ownerAddress: transfer.ownerAddress,
                targetAddress: transfer.destinationAddress,
                amountSun: transfer.amount,
                callData: nil,
                feeLimitSun: nil,
                memo: transfer.memo,
                txID: hash.hexString.lowercased()
            )
        case .contractCall(let call):
            details = .init(
                kind: .contractCall,
                ownerAddress: call.ownerAddress,
                targetAddress: call.contractAddress,
                amountSun: call.callValue,
                callData: call.callData.hexString.lowercased(),
                feeLimitSun: call.feeLimit,
                memo: call.memo,
                txID: hash.hexString.lowercased()
            )
        }

        // The signature authorises whatever `owner_address` says, not whatever `params.address` says.
        guard details.ownerAddress == expectedOwnerAddress else {
            throw WalletConnectTronRequestError.ownerMismatch
        }

        return SignableTransaction(rawData: rawData, hash: hash, parsed: details)
    }

    /// TIP-191 style personal message digest used by `tronWeb.trx.signMessageV2`:
    /// `keccak256("\x19TRON Signed Message:\n" ‖ decimal(byteLength) ‖ message)`.
    static func messageDigest(_ message: String) -> Data {
        let messageBytes = Data(message.utf8)
        var data = Data("\u{19}TRON Signed Message:\n".utf8)
        data.append(Data(String(messageBytes.count).utf8))
        data.append(messageBytes)
        return data.sha3(.keccak256)
    }

    /// Transaction signatures travel as 65 hex bytes `r ‖ s ‖ recid` with `recid` 0/1, as TronWeb emits them.
    /// The card path yields `v = 27 + recid` (Ethereum convention), so the last byte is rebased.
    static func transactionSignatureHex(from unmarshalledSignature: Data) throws -> String {
        var bytes = try normalized(unmarshalledSignature)
        bytes[64] -= 27
        return Data(bytes).hexString.lowercased()
    }

    /// Message signatures follow `signMessageV2`: `0x` ‖ 65 bytes with `v = 27 + recid`.
    static func messageSignatureHex(from unmarshalledSignature: Data) throws -> String {
        try "0x" + Data(normalized(unmarshalledSignature)).hexString.lowercased()
    }

    private static func normalized(_ signature: Data) throws -> [UInt8] {
        let bytes = [UInt8](signature)
        guard bytes.count == 65, (27 ... 28).contains(bytes[64]) else {
            throw WCTransactionSignError.signFailed
        }
        return bytes
    }
}

enum WalletConnectTronRequestError: LocalizedError, Equatable {
    case invalidRawData
    case txIDMismatch
    case unsupportedTransaction(String)
    case ownerMismatch

    var errorDescription: String? {
        switch self {
        case .invalidRawData:
            "raw_data_hex is not a valid Tron transaction"
        case .txIDMismatch:
            "txID does not match raw_data_hex"
        case .unsupportedTransaction(let reason):
            "Unsupported Tron transaction: \(reason)"
        case .ownerMismatch:
            "The transaction owner is not the connected account"
        }
    }
}
