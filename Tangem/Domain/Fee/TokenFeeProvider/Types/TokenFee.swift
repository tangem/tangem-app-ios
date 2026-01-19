//
//  TokenFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TokenFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let value: LoadingResult<BSDKFee, any Error>

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(tokenItem)
        hasher.combine("\(value)")
    }

    static func == (lhs: TokenFee, rhs: TokenFee) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - ErrorType

extension TokenFee {
    enum ErrorType: LocalizedError {
        case unsupportedByProvider
        case feeNotFound
        case loadingError(Error)

        var description: String? {
            switch self {
            case .unsupportedByProvider:
                return "Unsupported by provider"
            case .feeNotFound:
                return "Fee not found"
            case .loadingError(let error):
                return "\(error)"
            }
        }
    }
}
