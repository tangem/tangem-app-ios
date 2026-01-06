//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> [TokenFee]
    func getFee(dataType: TokenFeeProviderDataType) async throws -> [TokenFee]
}

enum TokenFeeProviderDataType {
    case plain(amount: Decimal, destination: String)
    case compiledTransaction(data: Data)
    case gaslessTransaction(feeToken: TokenItem, originalAmount: Decimal, originalDestination: String)
}

enum TokenFeeProviderError: LocalizedError {
    case tokenFeeProviderDataTypeNotSupported

    var errorDescription: String? {
        switch self {
        case .tokenFeeProviderDataTypeNotSupported: "TokenFeeProviderDataTypeNotSupported"
        }
    }
}
