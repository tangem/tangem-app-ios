//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainSdkError: Int, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    case signatureCountNotMatched = 0
    case failedToCreateMultisigScript = 1
    case failedToConvertPublicKey = 2
    case notImplemented = -1000
    case decodingFailed
    case failedToLoadFee
    case failedToLoadTxDetails
    case failedToFindTransaction
    case failedToFindTxInputs
    case feeForPushTxNotEnough
    case networkProvidersNotSupportsRbf
    case noAPIInfo

    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    public var errorDescription: String? {
        switch self {
        case .failedToLoadFee:
            return "common_fee_error".localized
        case .signatureCountNotMatched, .notImplemented:
            // [REDACTED_TODO_COMMENT]
            return "generic_error".localized
        default:
            return "generic_error".localized
        }
    }
    
    @available(*, deprecated, message: "Use errorDescription and errorCode instead")
    public var errorDescriptionWithCode: String {
        switch self {
        case .failedToLoadFee:
            return "common_fee_error".localized
        case .signatureCountNotMatched, .notImplemented:
            // [REDACTED_TODO_COMMENT]
            return "generic_error_code".localized(errorCodeDescription)
		default:
			return "generic_error_code".localized(errorCodeDescription)
		}
	}
    
    private var errorCodeDescription: String {
        "blockchain_sdk_error \(rawValue)"
    }
}

extension BlockchainSdkError: ErrorCodeProviding {
    public var errorCode: Int {
        rawValue
    }
}

public enum NetworkServiceError: Error {
    case notAvailable
}
