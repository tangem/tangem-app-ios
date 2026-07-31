//
//  SolanaTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

public struct SolanaTransactionHelper {
    public init() {}

    /// Removes signatures placeholders from transaction data
    /// - Parameter transaction: transaction data with placeholders
    /// - Returns: Transaction data without placeholders
    public func removeSignaturesPlaceholders(from transaction: Data) throws -> (transaction: Data, signatureCount: Int) {
        guard let firstByte = transaction.bytes.first else {
            BSDKLogger.error(error: "Failed to remove placeholders: transaction is empty")
            throw SolanaBSDKError.transactionIsEmpty
        }
        let signaturesPlaceholderLength = 1 + Int(firstByte) * Constants.signatureLength
        return (transaction.dropFirst(signaturesPlaceholderLength), signaturesPlaceholderLength / Constants.signatureLength)
    }

    public func addSignature(_ signature: Data, transaction: Data) throws -> String {
        let prepared = try removeSignaturesPlaceholders(from: transaction)
        let dataToSign = Data([UInt8(1)] + signature + prepared.transaction)
        return dataToSign.base64EncodedString()
    }

    /// Writes the wallet's `signature` into the signature slot of its own signer key by overwriting exactly those
    /// 64 bytes of the original `transaction`, leaving the signature count, the message, and every other slot
    /// byte-for-byte as received — including placeholders and signatures already supplied by the dApp for
    /// co-signers. This preserves multi-signer transactions (e.g. Meteora position creation), unlike a hardcoded
    /// single-signer reassembly that drops every slot but the first. The bytes are never re-serialized, so a
    /// signature computed over the original message stays valid.
    ///
    /// The slot index is resolved by matching `publicKey` against the transaction's required signers, so the
    /// signature lands at the right position even when the wallet is not the fee-payer at index 0. Parsing is done
    /// over a bounds-checked reader that throws on malformed input, so a truncated transaction from a dApp yields
    /// an error rather than a crash. Throws `SolanaBSDKError.signerPublicKeyNotFound` when `publicKey` is not a
    /// required signer of the transaction.
    public func putSignature(_ signature: Data, publicKey: Data, transaction: Data) throws -> Data {
        guard signature.count == Constants.signatureLength else {
            throw SolanaBSDKError.invalidSignatureLength
        }

        var reader = BinaryReader(bytes: transaction.bytes)
        let signatureSlotCount = try reader.decodeLength()
        let signaturesOffset = transaction.count - reader.remainBytes
        for _ in 0 ..< signatureSlotCount {
            _ = try reader.read(count: Constants.signatureLength)
        }
        let message = Data(try reader.readAll())

        let signerPublicKeys = try readSignerPublicKeys(from: message, maxSigners: signatureSlotCount)
        guard let signerIndex = signerPublicKeys.firstIndex(of: publicKey) else {
            throw SolanaBSDKError.signerPublicKeyNotFound
        }

        var signedTransaction = transaction
        let slotStart = signedTransaction.startIndex + signaturesOffset + signerIndex * Constants.signatureLength
        signedTransaction.replaceSubrange(slotStart ..< slotStart + Constants.signatureLength, with: signature)
        return signedTransaction
    }

    /// Reads the required-signer public keys from a serialized `message`: the first `numRequiredSignatures` static
    /// account keys, in order, capped by `maxSigners` (the actual number of signature slots) and by the account
    /// count so a malformed header can't point past the real signers. Uses a bounds-checked reader that throws on
    /// short input instead of trapping.
    private func readSignerPublicKeys(from message: Data, maxSigners: Int) throws -> [Data] {
        guard let firstByte = message.bytes.first else {
            throw SolanaBSDKError.transactionIsEmpty
        }

        var reader = BinaryReader(bytes: message.bytes)

        // Versioned (v0) messages prefix the header with `0x80 | version`; legacy messages start with the header.
        let isVersioned = firstByte & Constants.versionedMessageMask != 0
        if isVersioned {
            _ = try reader.read()
        }

        let numRequiredSignatures = Int(try reader.read())
        _ = try reader.read() // numReadonlySignedAccounts
        _ = try reader.read() // numReadonlyUnsignedAccounts

        let accountCount = try reader.decodeLength()
        let signerCount = min(numRequiredSignatures, accountCount, maxSigners)

        return try (0 ..< signerCount).map { _ in
            Data(try reader.read(count: Constants.publicKeyLength))
        }
    }

    public func transactionSize(withSignaturePlaceholders: Data) throws -> SolanaTransactionSize {
        let transaction = try removeSignaturesPlaceholders(from: withSignaturePlaceholders).transaction
        return transactionSize(withoutSignaturePlaceholders: transaction)
    }

    public func transactionSize(withoutSignaturePlaceholders: Data) -> SolanaTransactionSize {
        return withoutSignaturePlaceholders.count >= Constants.supportedTransactionSize ? .long : .default
    }
}

extension SolanaTransactionHelper {
    public enum SolanaTransactionSize {
        case `default`
        case long
    }

    private enum Constants {
        static let signatureLength: Int = 64
        static let publicKeyLength: Int = 32
        static let versionedMessageMask: UInt8 = 0x80

        /// Maximum APDU payload size in bytes.
        ///
        /// The full APDU packet is **1040 bytes**. Available payload space is calculated by:
        /// 1. Subtracting required service data
        /// 2. Subtracting derivation path size
        ///
        /// ### Formula:
        /// ```swift
        /// maxPayload = 1040 - serviceDataBytes - (derivationDepth * 4)
        /// ```
        ///
        /// ### Example:
        /// - Solana path `m/44'/501'/0'` (3 levels × 4 bytes = 12 bytes)
        /// - Service data varies by wallet type (e.g., Wallet 3 has different overhead)
        ///
        /// Use this constant for reference in payload building logic.
        /// Represents the practical APDU payload limit after accounting for service data and derivation path overhead.
        static let supportedTransactionSize: Int = 964
    }
}
