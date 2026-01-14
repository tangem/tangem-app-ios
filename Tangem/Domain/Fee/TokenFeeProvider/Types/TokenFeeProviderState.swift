//
//  TokenFeeProviderState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

enum TokenFeeProviderState {
    case idle
    case unavailable(TokenFeeProviderStateUnavailableReason)
    case loading
    case error(Error)
    case available([BSDKFee])
}

extension TokenFeeProviderState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .unavailable(let reason):
            return "unavailable with reason: (\(reason.rawCaseValue))"
        case .loading:
            return "loading"
        case .error(let error):
            return "error(\(String(describing: error)))"
        case .available(let fees):
            return "available(fees: \(fees.map(\.amount.description))"
        }
    }
}

@RawCaseName
enum TokenFeeProviderStateUnavailableReason {
    case inputDataNotSet
    case notSupported
    case notEnoughFeeBalance
}
