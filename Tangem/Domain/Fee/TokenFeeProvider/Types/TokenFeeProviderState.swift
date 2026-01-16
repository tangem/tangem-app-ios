//
//  TokenFeeProviderState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

@CaseFlagable
enum TokenFeeProviderState {
    case idle
    case unavailable(TokenFeeProviderStateUnavailableReason)
    case loading
    case error(Error)
    case available([BSDKFee])

    var isSupported: Bool {
        switch self {
        case .unavailable(.notSupported): false
        default: true
        }
    }
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
@CaseFlagable
enum TokenFeeProviderStateUnavailableReason {
    case inputDataNotSet
    case notSupported
    case notEnoughFeeBalance
    case noTokenBalance
}
