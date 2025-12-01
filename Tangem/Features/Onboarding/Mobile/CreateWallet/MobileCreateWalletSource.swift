//
//  MobileCreateWalletSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MobileCreateWalletSource {
    case createWallet
    case signIn
    case settings

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .createWallet: .createNewWallet
        case .signIn: .signIn
        case .settings: .settings
        }
    }
}
