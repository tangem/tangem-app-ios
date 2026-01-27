//
//  UserWalletConfigFeatures.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum UserWalletFeature: Int, CaseIterable { // [REDACTED_TODO_COMMENT]
    case accessCode
    case passcode
    case longTap
    case longHashes
    case backup
    case iCloudBackup
    case mnemonicBackup
    case twinning
    case hdWallets
    case userWalletAccessCode
    case userWalletBackup
    case userWalletUpgrade
    case signing
    case exchange
    case staking
    case cardSettings
    case walletConnect
    case multiCurrency
    case resetToFactory
    case referralProgram
    case swapping
    case displayHashesCount
    case transactionHistory
    case accessCodeRecoverySettings
    case nft
    case isBalanceRestrictionActive
    case nfcInteraction
    case transactionPayloadLimit
    case tangemPay
}

extension UserWalletFeature {
    enum Availability {
        case available
        case hidden
        case disabled(localizedReason: String? = nil)

        var disabledLocalizedReason: String? {
            if case .disabled(let reason) = self, let reason = reason {
                return reason
            }

            return nil
        }

        var isAvailable: Bool {
            if case .available = self {
                return true
            }

            return false
        }

        var isHidden: Bool {
            if case .hidden = self {
                return true
            }

            return false
        }

        static var demoStub: Availability {
            .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
        }
    }
}
