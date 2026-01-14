//
//  TokenFeesList.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

typealias TokenFeesList = [TokenFee]

extension TokenFeesList {
    var hasMultipleFeeOptions: Bool { unique(by: \.option).count > 1 }

    func eraseToLoadingResult() -> LoadingResult<[BSDKFee], any Error> {
        if contains(where: { $0.value.isLoading }) {
            return .loading
        }

        if let error = first(where: { $0.value.isFailure })?.value.error {
            return .failure(error)
        }

        let fees = compactMap { $0.value.value }

        assert(count == fees.count, "Some TokenFee doesn't have fee value")
        return .success(fees)
    }
}

// MARK: - TokenFeesList+

extension TokenFeesList {
    subscript(_ option: FeeOption) -> TokenFee? {
        first { $0.option == option }
    }
}
