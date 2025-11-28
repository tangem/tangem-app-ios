//
//  MobileOnboardingFlowSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MobileOnboardingFlowSource {
    case main(action: Analytics.ParameterValue)
    case importWallet
    case backup(action: Analytics.ParameterValue)
    case hardwareWallet(action: Analytics.ParameterValue)
    case walletSettings(action: Analytics.ParameterValue?)

    var analyticsParams: [Analytics.ParameterKey: Analytics.ParameterValue] {
        switch self {
        case .main(let action): [.source: .main, .action: action]
        case .importWallet: [.source: .importWallet]
        case .backup(let action): [.source: .backup, .action: action]
        case .hardwareWallet(let action): [.source: .hardwareWallet, .action: action]
        case .walletSettings(let action): [.source: .walletSettings, .action: action].compactMapValues { $0 }
        }
    }
}
