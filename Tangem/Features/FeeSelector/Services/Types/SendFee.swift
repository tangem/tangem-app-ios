//
//  SendFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

extension [SendFee] {
    var hasMultipleFeeOptions: Bool { unique(by: \.option).count > 1 }

    func eraseToLoadingResult() -> LoadingResult<[BSDKFee], any Error> {
        if contains(where: { $0.value.isLoading }) {
            return .loading
        }

        if let error = first(where: { $0.value.isFailure })?.value.error {
            return .failure(error)
        }

        let fees = compactMap { $0.value.value }

        assert(count == fees.count, "Some SendFee doesn't have fee value")
        return .success(fees)
    }
}

struct SendFee: Hashable {
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

    static func == (lhs: SendFee, rhs: SendFee) -> Bool {
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
