//
//  MobileWalletLimitUtil+Restriction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

extension MobileWalletLimitUtil {
    enum Restriction: Equatable {
        case mobileWalletsLimitReached(Addition)
        case socialWalletAlreadyAdded

        var analyticsParams: [Analytics.ParameterKey: String] {
            [
                .type: analyticsType.rawValue,
                .limit: analyticsLimit.rawValue,
            ]
        }

        static func makeMobileWalletsLimitAlert() -> AlertBinder {
            AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.hwWalletsLimitAlertTitle,
                message: Localization.hwWalletsLimitAlertMessage(MobileWalletLimit.maxCount),
                buttonText: Localization.commonGotIt
            )
        }

        func makeAlert() -> AlertBinder {
            switch self {
            case .mobileWalletsLimitReached:
                Self.makeMobileWalletsLimitAlert()
            case .socialWalletAlreadyAdded:
                AlertBuilder.makeAlertWithDefaultPrimaryButton(
                    title: Localization.socialWalletAlreadyAddedAlertTitle(MobileBackupConstants.appleServiceName),
                    message: Localization.socialWalletAlreadyAddedAlertMessage(MobileBackupConstants.appleServiceName),
                    buttonText: Localization.commonGotIt
                )
            }
        }

        private var analyticsType: Analytics.ParameterValue {
            switch self {
            case .mobileWalletsLimitReached(.create): .create
            case .mobileWalletsLimitReached(.import): .import
            case .mobileWalletsLimitReached(.socialLogin), .socialWalletAlreadyAdded: .socialLogin
            }
        }

        private var analyticsLimit: Analytics.ParameterValue {
            switch self {
            case .mobileWalletsLimitReached: .mobileWallets
            case .socialWalletAlreadyAdded: .socialLogin
            }
        }
    }
}
