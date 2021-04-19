//
//  BlockchainSdkError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BlockchainSdkError: Int, LocalizedError {
	case signatureCountNotMatched = 0
	case failedToCreateMultisigScript = 1
	case failedToConvertPublicKey = 2
	case notImplemented = -1000
    case decodingFailed
	
	public var errorDescription: String? {
		switch self {
		case .signatureCountNotMatched, .notImplemented:
			// [REDACTED_TODO_COMMENT]
			return "\(rawValue)"
		default:
			return "\(rawValue)"
		}
	}
}
