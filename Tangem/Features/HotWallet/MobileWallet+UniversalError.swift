//
//  MobileWalletError+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

extension MobileWalletError: UniversalError {
    var errorCode: Int {
        switch self {
        case .seedKeyNotFound:
            110000000
        }
    }
}
