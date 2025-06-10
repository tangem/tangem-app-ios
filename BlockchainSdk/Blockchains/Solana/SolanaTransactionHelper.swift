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
    public func removeSignaturesPlaceholders(from transaction: Data) throws -> Data {
        guard let firstByte = transaction.bytes.first else {
            BSDKLogger.error(error: "Failed to remove placeholders: transaction is empty")
            throw SolanaTransactionHelperError.transactionIsEmpty
        }
        let signaturesPlaceholderLength = 1 + Int(firstByte) * Constants.signatureLength
        return transaction.dropFirst(signaturesPlaceholderLength)
    }
}

enum SolanaTransactionHelperError: Error {
    case transactionIsEmpty
}

private extension SolanaTransactionHelper {
    enum Constants {
        static let signatureLength: Int = 64
    }
}
