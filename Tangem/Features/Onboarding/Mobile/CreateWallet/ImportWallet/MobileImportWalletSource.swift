//
//  MobileImportWalletSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MobileImportWalletSource {
    case importWallet
    case addNewWallet

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .importWallet: .importWallet
        case .addNewWallet: .addNewWallet
        }
    }
}
