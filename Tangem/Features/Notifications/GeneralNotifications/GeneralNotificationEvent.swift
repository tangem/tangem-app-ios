//
//  WarningEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemSdk

enum GeneralNotificationEvent: Equatable, Hashable {
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
    case supportedOnlySingleCurrencyWallet
    case backupErrors
    case seedSupport
    case seedSupport2
    case mobileFinishActivation(hasPositiveBalance: Bool, hasBackup: Bool)
    case mobileUpgrade
    case pushNotificationsPermissionRequest
}

/// For Notifications
extension GeneralNotificationEvent: NotificationEvent {
    var defaultTitle: String {
        Localization.commonWarning
    }

    var title: NotificationView.Title? {
        switch self {
        case .rateApp:
            return .string(Localization.warningRateAppTitle)
        case .failedToVerifyCard:
            return .string(Localization.warningFailedToVerifyCardTitle)
        case .systemDeprecationTemporary:
            return .string(Localization.warningSystemUpdateTitle)
        case .systemDeprecationPermanent:
            return .string(Localization.warningSystemDeprecationTitle)
        case .testnetCard:
            return .string(Localization.warningTestnetCardTitle)
        case .demoCard:
            return .string(Localization.warningDemoModeTitle)
        case .oldDeviceOldCard:
            return .string(Localization.warningOldDeviceOldCardTitle)
        case .oldCard:
            return .string(Localization.warningOldCardTitle)
        case .devCard:
            return .string(Localization.warningDeveloperCardTitle)
        case .lowSignatures:
            return .string(Localization.warningLowSignaturesTitle)
        case .numberOfSignedHashesIncorrect:
            return .string(Localization.warningNumberOfSignedHashesIncorrectTitle)
        case .legacyDerivation:
            return .string(defaultTitle)
        case .missingDerivation:
            return .string(Localization.warningMissingDerivationTitle)
        case .walletLocked:
            return .string(Localization.commonAccessDenied)
        case .missingBackup:
            return .string(Localization.warningNoBackupTitle)
        case .supportedOnlySingleCurrencyWallet:
            return .string(Localization.manageTokensWalletSupportOnlyOneNetworkTitle)
        case .backupErrors:
            return .string(Localization.commonAttention)
        case .seedSupport:
            return .string(Localization.warningSeedphraseIssueTitle)
        case .seedSupport2:
            return .string(Localization.warningSeedphraseActionRequiredTitle)
        case .mobileFinishActivation(let hasPositiveBalance, _):
            let text = Localization.hwActivationNeedTitle
            if hasPositiveBalance {
                var string = AttributedString(text)
                string.foregroundColor = Colors.Text.warning
                string.font = Fonts.Bold.footnote
                return .attributed(string)
            } else {
                return .string(text)
            }
        case .mobileUpgrade:
            return .string(Localization.hwUpgradeToColdBannerTitle)
        case .pushNotificationsPermissionRequest:
            return .string(Localization.userPushNotificationBannerTitle)
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
            return Localization.warningAccessDeniedMessage(BiometricsUtil.biometryType.name)
        case .missingBackup:
            return Localization.warningNoBackupMessage
        case .supportedOnlySingleCurrencyWallet:
            return nil
        case .backupErrors:
            return Localization.warningBackupErrorsMessage
        case .seedSupport:
            return Localization.warningSeedphraseIssueMessage
        case .seedSupport2:
            return Localization.warningSeedphraseContactedSupport
        case .mobileFinishActivation(_, let hasBackup):
            return hasBackup ? Localization.hwActivationNeedWarningDescription : Localization.hwActivationNeedDescription
        case .mobileUpgrade:
            return Localization.hwUpgradeToColdBannerDescription
        case .pushNotificationsPermissionRequest:
            return Localization.userPushNotificationBannerSubtitle
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .rateApp,
             .missingDerivation,
             .missingBackup,
             .seedSupport,
             .seedSupport2,
             .backupErrors,
             .mobileFinishActivation,
             .mobileUpgrade,
             .pushNotificationsPermissionRequest:
            return .primary
        default:
            return .secondary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .failedToVerifyCard, .devCard, .backupErrors, .seedSupport, .seedSupport2:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .numberOfSignedHashesIncorrect,
             .testnetCard,
             .oldDeviceOldCard,
             .oldCard,
             .lowSignatures,
             .systemDeprecationPermanent,
             .missingBackup,
             .supportedOnlySingleCurrencyWallet:
            return .init(iconType: .image(Assets.attention.image))
        case .demoCard, .legacyDerivation, .systemDeprecationTemporary, .missingDerivation:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .rateApp:
            return .init(iconType: .image(Assets.star.image))
        case .walletLocked:
            return .init(iconType: .image(Assets.lock.image), color: Colors.Icon.primary1)
        case .mobileFinishActivation(let hasPositiveBalance, _):
            let imageType = hasPositiveBalance ? Assets.criticalAttentionShield : Assets.attentionShield
            return .init(iconType: .image(imageType.image), size: CGSize(width: 16, height: 18))
        case .mobileUpgrade:
            return .init(iconType: .image(Assets.tangemInCircle.image), size: CGSize(width: 36, height: 36))
        case .pushNotificationsPermissionRequest:
            return .init(iconType: .image(Assets.pushNotifyBannerIcon.image), size: CGSize(width: 54, height: 54))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .walletLocked,
             .failedToVerifyCard,
             .devCard,
             .backupErrors,
             .seedSupport,
             .seedSupport2:
            return .critical
        case .demoCard,
             .legacyDerivation,
             .systemDeprecationTemporary,
             .missingDerivation,
             .rateApp,
             .mobileUpgrade,
             .pushNotificationsPermissionRequest:
            return .info
        case .numberOfSignedHashesIncorrect,
             .testnetCard,
             .oldDeviceOldCard,
             .oldCard,
             .lowSignatures,
             .systemDeprecationPermanent,
             .missingBackup,
             .supportedOnlySingleCurrencyWallet,
             .mobileFinishActivation:
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .failedToVerifyCard,
             .testnetCard,
             .devCard,
             .oldDeviceOldCard,
             .oldCard,
             .demoCard,
             .lowSignatures,
             .legacyDerivation,
             .systemDeprecationPermanent,
             .missingDerivation,
             .walletLocked,
             .missingBackup,
             .supportedOnlySingleCurrencyWallet,
             .backupErrors,
             .seedSupport,
             .seedSupport2,
             .mobileFinishActivation:
            return false
        case .numberOfSignedHashesIncorrect,
             .systemDeprecationTemporary,
             .rateApp,
             .mobileUpgrade,
             .pushNotificationsPermissionRequest:
            return true
        }
    }

    var buttonAction: NotificationButtonAction? {
        // [REDACTED_TODO_COMMENT]
        nil
    }

    func style(
        tapAction: NotificationView.NotificationAction? = nil,
        buttonAction: NotificationView.NotificationButtonTapAction? = nil
    ) -> NotificationView.Style {
        switch self {
        case .walletLocked:
            guard let tapAction else {
                break
            }

            return .tappable(hasChevron: true, action: tapAction)
        case .missingBackup:
            guard let buttonAction else {
                break
            }

            return .withButtons([
                NotificationView.NotificationButton(action: buttonAction, actionType: .backupCard, isWithLoader: false),
            ])
        case .missingDerivation:
            guard let buttonAction else {
                break
            }

            return .withButtons([
                .init(action: buttonAction, actionType: .generateAddresses, isWithLoader: true),
            ])
        case .rateApp:
            guard let buttonAction else {
                break
            }

            return .withButtons([
                .init(action: buttonAction, actionType: .openFeedbackMail, isWithLoader: false),
                .init(action: buttonAction, actionType: .openAppStoreReview, isWithLoader: false),
            ])
        case .backupErrors:
            guard let buttonAction else {
                break
            }

            return .withButtons([
                .init(action: buttonAction, actionType: .support, isWithLoader: false),
            ])
        case .mobileFinishActivation(let hasPositiveBalance, _):
            guard let buttonAction else {
                break
            }
            return .withButtons([
                .init(
                    action: buttonAction,
                    actionType: .openMobileFinishActivation(needsAttention: hasPositiveBalance),
                    isWithLoader: false
                ),
            ])
        case .mobileUpgrade:
            guard let tapAction else {
                break
            }
            return .tappable(hasChevron: false, action: tapAction)
        default: break
        }
        return .plain
    }
}

// MARK: Analytics info

extension GeneralNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .numberOfSignedHashesIncorrect: return .mainNoticeCardSignedTransactions
        case .rateApp: return nil // Analytics is sent by `RateAppService`
        case .failedToVerifyCard: return .mainNoticeProductSampleCard
        case .testnetCard: return .mainNoticeTestnetCard
        case .demoCard: return .mainNoticeDemoCard
        case .oldDeviceOldCard: return .mainNoticeOldCard
        case .oldCard: return .mainNoticeOldCard
        case .devCard: return .mainNoticeDevelopmentCard
        case .lowSignatures: return nil
        case .legacyDerivation: return nil
        case .systemDeprecationTemporary: return nil
        case .systemDeprecationPermanent: return nil
        case .missingDerivation: return .mainNoticeMissingAddress
        case .walletLocked: return .mainNoticeWalletUnlock
        case .missingBackup: return .mainNoticeBackupYourWallet
        case .supportedOnlySingleCurrencyWallet: return nil
        case .backupErrors: return .mainNoticeBackupErrors
        case .seedSupport: return .mainNoticeSeedSupport
        case .seedSupport2: return .mainNoticeSeedSupport2
        case .mobileFinishActivation: return .noticeFinishActivation
        case .mobileUpgrade: return nil
        case .pushNotificationsPermissionRequest: return .promoPushBanner
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .mobileFinishActivation(let hasPositiveBalance, let hasBackup):
            let balanceStateValue: Analytics.ParameterValue = hasPositiveBalance ? .full : .empty
            let activationStateValue: Analytics.ParameterValue = hasBackup ? .unfinished : .notStarted
            return [
                .balanceState: balanceStateValue.rawValue,
                .activationState: activationStateValue.rawValue,
            ]
        default:
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool {
        switch self {
        // Missing derivation notification can be tracked multiple times because if user make changes for
        // one card on different devices the `Missing derivation` notification will be updated
        // and we need to track this update after PTR
        case .missingDerivation: return false
        default: return true
        }
    }
}
