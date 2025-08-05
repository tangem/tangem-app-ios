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

    case send
    case receive

    case topup
    case withdrawal
    case exchange
    case staking

    case walletConnect
    case multiCurrency
    case resetToFactory
    /// Count signed hashes to display warning for user if card already sign hashes in the past.
    case signedHashesCounter
    /// Is wallet allowed to participate in referral program
    case referralProgram

    /// Synchronize tokens between devices using`userWalletId`
    /// Only for issued cards with multiple wallets
    case tokenSynchronization

    case swapping
    case displayHashesCount
    case transactionHistory

    case accessCodeRecoverySettings

    case promotion

    case nft
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
