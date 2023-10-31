//
//  WarningEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum WarningEvent: Equatable {
    case numberOfSignedHashesIncorrect
    case rateApp
    case failedToVerifyCard
    case testnetCard
    case demoCard
    case oldDeviceOldCard
    case oldCard
    case devCard
    case lowSignatures(count: Int)
    case legacyDerivation
    case systemDeprecationTemporary
    case systemDeprecationPermanent(String)
    case missingDerivation(numberOfNetworks: Int)
    case walletLocked
    case missingBackup
}

// For Notifications
extension WarningEvent: NotificationEvent {
    var defaultTitle: String {
        Localization.commonWarning
    }

    var title: String {
        switch self {
        case .rateApp:
            return Localization.warningRateAppTitle
        case .failedToVerifyCard:
            return Localization.warningFailedToVerifyCardTitle
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateTitle
        case .systemDeprecationPermanent:
            return Localization.warningSystemDeprecationTitle
        case .testnetCard:
            return Localization.warningTestnetCardTitle
        case .demoCard:
            return Localization.warningDemoModeTitle
        case .oldDeviceOldCard:
            return Localization.warningOldDeviceOldCardTitle
        case .oldCard:
            return Localization.warningOldCardTitle
        case .devCard:
            return Localization.warningDeveloperCardTitle
        case .lowSignatures:
            return Localization.warningLowSignaturesTitle
        case .numberOfSignedHashesIncorrect:
            return Localization.warningNumberOfSignedHashesIncorrectTitle
        case .legacyDerivation:
            return defaultTitle
        case .missingDerivation:
            return Localization.warningMissingDerivationTitle
        case .walletLocked:
            return Localization.commonAccessDenied
        case .missingBackup:
            return Localization.warningNoBackupTitle
        }
    }

    var description: String? {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return Localization.warningNumberOfSignedHashesIncorrectMessage
        case .rateApp:
            return Localization.warningRateAppMessage
        case .failedToVerifyCard:
            return Localization.warningFailedToVerifyCardMessage
        case .testnetCard:
            return Localization.warningTestnetCardMessage
        case .demoCard:
            return Localization.warningDemoModeMessage
        case .oldDeviceOldCard:
            return Localization.warningOldDeviceOldCardMessage
        case .oldCard:
            return Localization.warningOldCardMessage
        case .devCard:
            return Localization.warningDeveloperCardMessage
        case .lowSignatures(let count):
            return Localization.warningLowSignaturesMessage("\(count)")
        case .legacyDerivation:
            return Localization.warningManageTokensLegacyDerivationMessage
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateMessage
        case .systemDeprecationPermanent(let dateString):
            return String(format: Localization.warningSystemDeprecationWithDateMessage(dateString))
                .replacingOccurrences(of: "..", with: ".")
        case .missingDerivation(let numberOfNetworks):
            return Localization.warningMissingDerivationMessage(numberOfNetworks)
        case .walletLocked:
            return Localization.warningAccessDeniedMessage(BiometricAuthorizationUtils.biometryType.name)
        case .missingBackup:
            return Localization.warningNoBackupMessage
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .rateApp, .missingDerivation, .missingBackup:
            return .primary
        default:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .failedToVerifyCard, .devCard:
            return .init(image: Assets.redCircleWarning.image)
        case .numberOfSignedHashesIncorrect, .testnetCard, .oldDeviceOldCard, .oldCard, .lowSignatures, .systemDeprecationPermanent, .missingBackup:
            return .init(image: Assets.attention.image)
        case .demoCard, .legacyDerivation, .systemDeprecationTemporary, .missingDerivation:
            return .init(image: Assets.blueCircleWarning.image)
        case .rateApp:
            return .init(image: Assets.star.image)
        case .walletLocked:
            return .init(image: Assets.lock.image, color: Colors.Icon.primary1)
        }
    }

    var isDismissable: Bool {
        switch self {
        case .failedToVerifyCard, .testnetCard, .devCard, .oldDeviceOldCard, .oldCard, .demoCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent, .missingDerivation, .walletLocked, .missingBackup:
            return false
        case .rateApp, .numberOfSignedHashesIncorrect, .systemDeprecationTemporary:
            return true
        }
    }

    var hasAction: Bool {
        switch self {
        case .walletLocked:
            return true
        default:
            return false
        }
    }
}
