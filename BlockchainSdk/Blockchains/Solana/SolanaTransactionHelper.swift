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
    public func removeSignaturesPlaceholders(from transaction: Data) throws -> (transaction: Data, count: Int) {
        guard let firstByte = transaction.bytes.first else {
            BSDKLogger.error(error: "Failed to remove placeholders: transaction is empty")
            throw SolanaBSDKError.transactionIsEmpty
        }
        let signaturesPlaceholderLength = 1 + Int(firstByte) * Constants.signatureLength
        return (transaction.dropFirst(signaturesPlaceholderLength), signaturesPlaceholderLength / Constants.signatureLength)
    }

    func prepareForSign(_ unsignedData: String) throws -> Data {
        let (transaction, _) = try removeSignaturesPlaceholders(from: Data(hex: unsignedData))
        return transaction
    }

    func prepareForSend(_ unsignedData: String, signature: Data) throws -> String {
        let prepared = try prepareForSign(unsignedData)
        let dataToSign = Data([UInt8(1)] + signature + prepared)
        return dataToSign.base64EncodedString()
    }
}

private extension SolanaTransactionHelper {
    enum Constants {
        static let signatureLength: Int = 64
    }
}
