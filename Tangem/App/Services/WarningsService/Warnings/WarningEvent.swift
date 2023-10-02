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
    case multiWalletSignedHashes
    case rateApp
    case failedToValidateCard
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

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch self {
        case .multiWalletSignedHashes:
            // We don't need any special symbol in Notifications
            return Localization.warningImportantSecurityInfo("")
        case .rateApp:
            return Localization.warningRateAppTitle
        case .failedToValidateCard:
            return Localization.warningFailedToVerifyCardTitle
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateTitle
        case .systemDeprecationPermanent:
            return Localization.warningSystemDeprecationTitle
        case .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .numberOfSignedHashesIncorrect, .legacyDerivation:
            return defaultTitle
        case .missingDerivation:
            return Localization.mainWarningMissingDerivationTitle
        case .walletLocked:
            return Localization.commonUnlockNeeded
        case .missingBackup:
            return Localization.mainNoBackupWarningTitle
        }
    }

    var description: String? {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return Localization.alertCardSignedTransactions
        case .multiWalletSignedHashes:
            return Localization.warningSignedTxPreviously
        case .rateApp:
            return Localization.warningRateAppMessage
        case .failedToValidateCard:
            return Localization.warningFailedToVerifyCardMessage
        case .testnetCard:
            return Localization.warningTestnetCardMessage
        case .demoCard:
            return Localization.alertDemoMessage
        case .oldDeviceOldCard:
            return Localization.alertOldDeviceThisCard
        case .oldCard:
            return Localization.alertOldCard
        case .devCard:
            return Localization.alertDeveloperCard
        case .lowSignatures(let count):
            return Localization.warningLowSignaturesFormat("\(count)")
        case .legacyDerivation:
            return Localization.alertManageTokensAddressesMessage
        case .systemDeprecationTemporary:
            return Localization.warningSystemUpdateMessage
        case .systemDeprecationPermanent(let dateString):
            return String(format: Localization.warningSystemDeprecationWithDateMessage(dateString))
                .replacingOccurrences(of: "..", with: ".")
        case .missingDerivation(let numberOfNetworks):
            return Localization.mainWarningMissingDerivationDescription(numberOfNetworks)
        case .walletLocked:
            return Localization.unlockWalletDescriptionShort(BiometricAuthorizationUtils.biometryType.name)
        case .missingBackup:
            return Localization.mainNoBackupWarningSubtitle
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .rateApp, .missingDerivation, .missingBackup:
            return .white
        default:
            return .gray
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .multiWalletSignedHashes, .numberOfSignedHashesIncorrect, .failedToValidateCard, .testnetCard, .devCard, .demoCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .init(image: Assets.redCircleWarning.image)
        case .rateApp, .oldDeviceOldCard, .oldCard, .systemDeprecationTemporary:
            return .init(image: Assets.attention.image)
        case .missingDerivation:
            return .init(image: Assets.blueCircleWarning.image)
        case .walletLocked:
            return .init(image: Assets.lock.image, color: Colors.Icon.primary1)
        case .missingBackup:
            return .init(image: Assets.attention.image)
        }
    }

    var isDismissable: Bool {
        switch self {
        case .multiWalletSignedHashes, .failedToValidateCard, .testnetCard, .devCard, .oldDeviceOldCard, .oldCard, .demoCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent, .missingDerivation, .walletLocked, .missingBackup:
            return false
        case .rateApp, .numberOfSignedHashesIncorrect, .systemDeprecationTemporary:
            return true
        }
    }

    var hasAction: Bool {
        switch self {
        case .multiWalletSignedHashes, .walletLocked:
            return true
        default:
            return false
        }
    }
}
