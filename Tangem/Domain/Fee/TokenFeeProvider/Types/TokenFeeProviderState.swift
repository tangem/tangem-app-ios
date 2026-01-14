//
//  TokenFeeProviderState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TokenFeeProviderState {
    case idle
    case unavailable(TokenFeeProviderStateUnavailableReason)
    case loading
    case error(Error)
    case available([BSDKFee])
}

enum TokenFeeProviderStateUnavailableReason {
    case inputDataNotSet
    case notSupported
    case notEnoughFeeBalance
}
