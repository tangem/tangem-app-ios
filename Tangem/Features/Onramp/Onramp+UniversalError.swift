//
//  Onramp+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// `Subsystems`:
// `000` - OnrampAmountInteractorBottomInfoError
// `001` -
// `002` -
// `003` -
// `004` -
// `005` -
// `006` -

extension OnrampAmountInteractorBottomInfoError: UniversalError {
    var errorCode: Int {
        switch self {
        case .noAvailableProviders:
            109000000
        case .tooBigAmount:
            109000001
        case .tooSmallAmount:
            109000002
        }
    }
}
