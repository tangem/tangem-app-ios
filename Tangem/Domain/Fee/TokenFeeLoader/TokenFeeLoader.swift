//
//  TokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee]
    func getFee(dataType: TokenFeeLoaderDataType) async throws -> [BSDKFee]
}

enum TokenFeeLoaderDataType {
    case plain(amount: Decimal, destination: String)
    case compiledTransaction(data: Data)
    case gaslessTransaction(feeToken: TokenItem, originalAmount: Decimal, originalDestination: String)
}

enum TokenFeeLoaderError: LocalizedError {
    case tokenFeeLoaderDataTypeNotSupported

    var errorDescription: String? {
        switch self {
        case .tokenFeeLoaderDataTypeNotSupported: "TokenFeeLoaderDataTypeNotSupported"
        }
    }
}
