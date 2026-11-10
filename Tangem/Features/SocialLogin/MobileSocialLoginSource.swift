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
    case addNewWallet

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .createWallet: .createWallet
        case .importWallet: .importWallet
        case .addNewWallet: .addNewWallet
        }
    }
}
