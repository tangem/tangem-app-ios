//
//  SolanaBSDKError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum SolanaBSDKError: Error {
    case transactionIsEmpty
    case notImplemented
    case signerPublicKeyNotFound
    case invalidSignatureLength
    case invalidCompactU16
    case invalidBlockhashLength
    case unsupportedMessageVersion
    case durableNonceTransaction
    case unexpectedTransactionMutation
    case programIdOutsideStaticKeys
}
