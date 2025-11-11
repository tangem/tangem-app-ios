//
//  SolanaTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
