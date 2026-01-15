//
//  LoadableTokenFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

struct TokenFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let fee: BSDKFee
}

struct LoadableTokenFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let value: LoadingResult<BSDKFee, any Error>

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(tokenItem)

        switch value {
        case .loading:
            hasher.combine("loading")
        case .success(let value):
            hasher.combine(value)
        case .failure(let error):
            hasher.combine(error.localizedDescription)
        }
    }

    static func == (lhs: LoadableTokenFee, rhs: LoadableTokenFee) -> Bool {
        guard lhs.option == rhs.option else { return false }

        switch (lhs.value, rhs.value) {
        case (.loading, .loading):
            return true
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
