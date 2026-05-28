//
//  NotificationButtonActionType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemUI

struct NotificationButtonAction {
    let type: NotificationButtonActionType
    let withLoader: Bool
    let isDisabled: Bool

    init(_ type: NotificationButtonActionType, withLoader: Bool = false, isDisabled: Bool = false) {
        self.type = type
        self.withLoader = withLoader
        self.isDisabled = isDisabled
    }
}

enum NotificationButtonActionType: Identifiable {
    case generateAddresses(icon: MainButton.Icon?)
    case backupCard
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case leaveAmount(amount: Decimal, amountFormatted: String)
    case reduceAmountBy(amount: Decimal, amountFormatted: String, needsAttention: Bool = false)
    case reduceAmountTo(amount: Decimal, amountFormatted: String)
    case openLink(promotionLink: URL, buttonTitle: String)
    case openDeeplink(url: URL, buttonTitle: String)
    case swap
    case addHederaTokenAssociation
    case addTokenTrustline
    case retryKaspaTokenTransaction(icon: MainButton.Icon?)
    case stake
    case openCloreMigration
    case openDynamicAddressesEnter
    /// Rate the app
    case openFeedbackMail
    /// Rate the app.
    case openAppStoreReview
    /// No action
    case empty
    case support
    case openCurrency
    case unlock(icon: MainButton.Icon?)
    case renewTangemPaySession(icon: MainButton.Icon?)
    case openMobileFinishActivation(needsAttention: Bool)
    case openMobileUpgrade
    case closeMobileUpgrade
    case allowPushPermissionRequest
    case postponePushPermissionRequest
    case openPushNotificationsSystemSettings
    case activate
    case givePermission
    case openManageTokensAfterWalletSuccessImport
    case openYieldBoostPromo(buttonTitle: String)
    case addFunds

    var id: Int {
        switch self {
        case .generateAddresses: "generateAddresses".hashValue
        case .backupCard: "backupCard".hashValue
        case .openFeeCurrency(let currencySymbol): "openFeeCurrency\(currencySymbol)".hashValue
        case .refresh: "refresh".hashValue
        case .refreshFee: "refresh_fee".hashValue
        case .goToProvider: "goToProvider".hashValue
        case .leaveAmount(let amount, let amountFormatted): "leaveAmount\(amount)\(amountFormatted)".hashValue
        case .reduceAmountBy(let amount, let amountFormatted, _): "reduceAmountBy\(amount)\(amountFormatted)".hashValue
        case .reduceAmountTo(let amount, let amountFormatted): "reduceAmountTo\(amount)\(amountFormatted)".hashValue
        case .openLink(let promotionLink, let buttonTitle): "openLink\(promotionLink)\(buttonTitle)".hashValue
        case .openDeeplink(let url, let buttonTitle): "openDeeplink\(url)\(buttonTitle)".hashValue
        case .swap: "swap".hashValue
        case .addHederaTokenAssociation: "addHederaTokenAssociation".hashValue
        case .addTokenTrustline: "addTokenTrustline".hashValue
        case .retryKaspaTokenTransaction: "retryKaspaTokenTransaction".hashValue
        case .stake: "stake".hashValue
        case .openCloreMigration: "openCloreMigration".hashValue
        case .openDynamicAddressesEnter: "openDynamicAddressesEnter".hashValue
        case .openFeedbackMail: "openFeedbackMail".hashValue
        case .openAppStoreReview: "openAppStoreReview".hashValue
        case .empty: "empty".hashValue
        case .support: "support".hashValue
        case .openCurrency: "openCurrency".hashValue
        case .unlock: "unlock".hashValue
        case .renewTangemPaySession: "renewTangemPaySession".hashValue
        case .openMobileFinishActivation(let needsAttention): "openMobileFinishActivation\(needsAttention)".hashValue
        case .openMobileUpgrade: "openMobileUpgrade".hashValue
        case .closeMobileUpgrade: "closeMobileUpgrade".hashValue
        case .allowPushPermissionRequest: "allowPushPermissionRequest".hashValue
        case .postponePushPermissionRequest: "postponePushPermissionRequest".hashValue
        case .openPushNotificationsSystemSettings: "openPushNotificationsSystemSettings".hashValue
        case .activate: "activate".hashValue
        case .givePermission: "givePermission".hashValue
        case .openManageTokensAfterWalletSuccessImport: "openManageTokensAfterWalletSuccessImport".hashValue
        case .openYieldBoostPromo(let buttonTitle): "openYieldBoostPromo\(buttonTitle)".hashValue
        case .addFunds: "addFunds".hashValue
        }
    }

    var title: String {
        switch self {
        case .generateAddresses:
            return Localization.commonGenerateAddresses
        case .backupCard:
            return Localization.buttonStartBackupProcess
        case .openFeeCurrency(let currencySymbol):
            return Localization.commonBuyCurrency(currencySymbol)
        case .refresh, .refreshFee:
            return Localization.warningButtonRefresh
        case .goToProvider:
            return Localization.commonGoToProvider
        case .reduceAmountBy(_, let amountFormatted, _):
            return Localization.sendNotificationReduceBy(amountFormatted)
        case .reduceAmountTo(_, let amountFormatted), .leaveAmount(_, let amountFormatted):
            return Localization.sendNotificationLeaveButton(amountFormatted)
        case .openLink(_, let buttonTitle):
            return buttonTitle
        case .openDeeplink(_, let buttonTitle):
            return buttonTitle
        case .addHederaTokenAssociation:
            return Localization.warningHederaMissingTokenAssociationButtonTitle
        case .retryKaspaTokenTransaction:
            return Localization.alertButtonTryAgain
        case .stake:
            return Localization.commonStake
        case .openFeedbackMail:
            return Localization.warningButtonCouldBeBetter
        case .openAppStoreReview:
            return Localization.warningButtonReallyCool
        case .swap:
            return Localization.tokenSwapPromotionButton
        case .empty:
            return ""
        case .support:
            return Localization.commonContactSupport
        case .openCurrency:
            return Localization.commonGoToToken
        case .unlock:
            return Localization.visaUnlockNotificationButton
        case .renewTangemPaySession:
            return Localization.tangempaySyncNeededButton
        case .addTokenTrustline:
            return Localization.warningTokenTrustlineButtonTitle
        case .openMobileFinishActivation:
            return Localization.hwActivationNeedFinish
        case .openMobileUpgrade:
            return Localization.hwUpgrade
        case .closeMobileUpgrade:
            return Localization.commonLater
        case .allowPushPermissionRequest:
            return Localization.commonEnable
        case .postponePushPermissionRequest:
            return Localization.commonLater
        case .openPushNotificationsSystemSettings:
            return Localization.commonOpenSettingsButtonTitle
        case .activate:
            return Localization.commonActivate
        case .givePermission:
            return Localization.givePermissionTitle
        case .openCloreMigration:
            return Localization.warningCloreMigrationButton
        case .openDynamicAddressesEnter:
            return Localization.commonLearnMore
        case .openManageTokensAfterWalletSuccessImport:
            return Localization.mainManageTokens
        case .openYieldBoostPromo(let buttonTitle):
            return buttonTitle
        case .addFunds:
            return Localization.commonAddFunds
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses(let icon),
             .retryKaspaTokenTransaction(let icon),
             .unlock(let icon),
             .renewTangemPaySession(let icon):
            return icon
        case .swap:
            return .leading(Assets.exchangeMini)
        case .backupCard,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .leaveAmount,
             .addHederaTokenAssociation,
             .openLink,
             .openDeeplink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support,
             .openCurrency,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .closeMobileUpgrade,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .openPushNotificationsSystemSettings,
             .activate,
             .givePermission,
             .openCloreMigration,
             .openDynamicAddressesEnter,
             .openManageTokensAfterWalletSuccessImport,
             .openYieldBoostPromo,
             .addFunds:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .openAppStoreReview,
             .empty,
             .unlock,
             .renewTangemPaySession,
             .openMobileUpgrade,
             .allowPushPermissionRequest,
             .activate,
             .openYieldBoostPromo,
             .addFunds:
            return .primary
        case .backupCard,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .openLink,
             .openDeeplink,
             .support,
             .stake,
             .openFeedbackMail,
             .openCurrency,
             .swap,
             .addTokenTrustline,
             .postponePushPermissionRequest,
             .openPushNotificationsSystemSettings,
             .givePermission,
             .openCloreMigration,
             .openDynamicAddressesEnter,
             .closeMobileUpgrade,
             .openManageTokensAfterWalletSuccessImport:
            return .secondary
        case .openMobileFinishActivation(let needsAttention), .reduceAmountBy(_, _, let needsAttention):
            return needsAttention ? .primary : .secondary
        }
    }
}
