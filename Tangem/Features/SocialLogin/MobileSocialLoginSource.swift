//
//  MobileSocialLoginSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MobileSocialLoginSource {
    case createWallet
    case importWallet

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .createWallet: .create
        case .importWallet: .importWallet
        }
    }
}
