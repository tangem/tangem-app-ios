//
//  MobileOnboardingFlowSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MobileOnboardingFlowSource {
    case main(action: MainAction)
    case importWallet
    case backup(action: BackupAction)
    case hardwareWallet(action: HardwareWalletAction)
    case walletSettings(action: WalletSettingsAction?)

    var analyticsParams: [Analytics.ParameterKey: Analytics.ParameterValue] {
        switch self {
        case .main(let action): [.source: .main, .action: action.analyticsParameterValue]
        case .importWallet: [.source: .importWallet]
        case .backup(let action): [.source: .backup, .action: action.analyticsParameterValue]
        case .hardwareWallet(let action): [.source: .hardwareWallet, .action: action.analyticsParameterValue]
        case .walletSettings(let action): [.source: .walletSettings, .action: action?.analyticsParameterValue].compactMapValues { $0 }
        }
    }

    enum MainAction {
        case backup

        var analyticsParameterValue: Analytics.ParameterValue {
            switch self {
            case .backup: .backup
            }
        }
    }

    enum BackupAction {
        case accessCode
        case backup

        var analyticsParameterValue: Analytics.ParameterValue {
            switch self {
            case .accessCode: .accessCode
            case .backup: .backup
            }
        }
    }

    enum HardwareWalletAction {
        case upgrade

        var analyticsParameterValue: Analytics.ParameterValue {
            switch self {
            case .upgrade: .upgrade
            }
        }
    }

    enum WalletSettingsAction {
        case accessCode
        case upgrade
        case remove

        var analyticsParameterValue: Analytics.ParameterValue {
            switch self {
            case .accessCode: .accessCode
            case .upgrade: .upgrade
            case .remove: .remove
            }
        }
    }
}
