//
//  MobileCreateWalletSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MobileCreateWalletSource {
    case createWalletIntro
    case addNewWallet

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .createWalletIntro: .createWalletIntro
        case .addNewWallet: .addNewWallet
        }
    }
}
