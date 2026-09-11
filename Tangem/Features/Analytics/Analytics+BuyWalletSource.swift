//
//  Analytics+BuyWalletSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum BuyWalletSource {
        case createWallet
        case createWalletIntro
        case addWallet
        case hardwareWallet
        case settings
        case upgrade

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .createWallet: .create
            case .createWalletIntro: .createWalletIntro
            case .addWallet: .addNewWallet
            case .hardwareWallet: .hardwareWallet
            case .settings: .settings
            case .upgrade: .upgrade
            }
        }
    }
}
