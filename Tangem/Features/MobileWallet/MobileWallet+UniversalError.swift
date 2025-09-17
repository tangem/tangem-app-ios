//
//  MobileWalletError+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// `Subsystems`:
// `000` - CommonError
// `001` - Upgrade wallet

extension MobileWalletError: UniversalError {
    var errorCode: Int {
        switch self {
        case .seedKeyNotFound:
            110000000
        }
    }
}

extension MobileUpgradeViewModel.UpgradeError: UniversalError {
    var errorCode: Int {
        switch self {
        case .cardAlreadyHasWallet:
            110001000
        case .wallet2CardRequired:
            110001001
        case .cardDoesNotAllowKeyImport:
            110001002
        }
    }
}
