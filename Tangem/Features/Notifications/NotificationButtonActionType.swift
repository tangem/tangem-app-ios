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
    case generateAddresses
    case backupCard
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case leaveAmount(amount: Decimal, amountFormatted: String)
    case reduceAmountBy(amount: Decimal, amountFormatted: String, needsAttention: Bool = false)
    case reduceAmountTo(amount: Decimal, amountFormatted: String)
    case openLink(promotionLink: URL, buttonTitle: String)
    case swap
    case addHederaTokenAssociation
    case addTokenTrustline
    case retryKaspaTokenTransaction
    case stake
    /// Rate the app
    case openFeedbackMail
    /// Rate the app.
    case openAppStoreReview
    /// No action
    case empty
    case support
    case openCurrency
    case seedSupportYes
    case seedSupportNo
    case seedSupport2Yes
    case seedSupport2No
    case unlock
    case openMobileFinishActivation(needsAttention: Bool)
    case openMobileUpgrade
    case tangemPaySync(title: String)
    case allowPushPermissionRequest
    case postponePushPermissionRequest
    case activate
    case givePermission

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
        case .swap: "swap".hashValue
        case .addHederaTokenAssociation: "addHederaTokenAssociation".hashValue
        case .addTokenTrustline: "addTokenTrustline".hashValue
        case .retryKaspaTokenTransaction: "retryKaspaTokenTransaction".hashValue
        case .stake: "stake".hashValue
        case .openFeedbackMail: "openFeedbackMail".hashValue
        case .openAppStoreReview: "openAppStoreReview".hashValue
        case .empty: "empty".hashValue
        case .support: "support".hashValue
        case .openCurrency: "openCurrency".hashValue
        case .seedSupportYes: "seedSupportYes".hashValue
        case .seedSupportNo: "seedSupportNo".hashValue
        case .seedSupport2Yes: "seedSupport2Yes".hashValue
        case .seedSupport2No: "seedSupport2No".hashValue
        case .unlock: "unlock".hashValue
        case .openMobileFinishActivation(let needsAttention): "openMobileFinishActivation\(needsAttention)".hashValue
        case .openMobileUpgrade: "openMobileUpgrade".hashValue
        case .tangemPaySync: "tangemPaySync".hashValue
        case .allowPushPermissionRequest: "allowPushPermissionRequest".hashValue
        case .postponePushPermissionRequest: "postponePushPermissionRequest".hashValue
        case .activate: "activate".hashValue
        case .givePermission: "givePermission".hashValue
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
        case .seedSupportYes:
            return Localization.commonYes
        case .seedSupportNo:
            return Localization.commonNo
        case .seedSupport2Yes:
            return Localization.seedWarningYes
        case .seedSupport2No:
            return Localization.seedWarningNo
        case .unlock:
            return Localization.visaUnlockNotificationButton
        case .addTokenTrustline:
            return Localization.warningTokenTrustlineButtonTitle
        case .openMobileFinishActivation:
            return Localization.hwActivationNeedFinish
        case .openMobileUpgrade:
            return .empty
        case .tangemPaySync(let title):
            return title
        case .allowPushPermissionRequest:
            return Localization.commonEnable
        case .postponePushPermissionRequest:
            return Localization.commonLater
        case .activate:
            return Localization.commonActivate
        case .givePermission:
            return Localization.givePermissionTitle
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses,
             .retryKaspaTokenTransaction,
             .unlock,
             .tangemPaySync:
            return .trailing(Assets.tangemIcon)
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
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .empty,
             .support,
             .openCurrency,
             .seedSupportYes,
             .seedSupportNo,
             .seedSupport2Yes,
             .seedSupport2No,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest,
             .activate,
             .givePermission:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .openAppStoreReview,
             .empty,
             .unlock,
             .openMobileUpgrade,
             .allowPushPermissionRequest,
             .activate,
             .tangemPaySync:
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
             .support,
             .stake,
             .openFeedbackMail,
             .openCurrency,
             .swap,
             .seedSupportNo,
             .seedSupportYes,
             .seedSupport2Yes,
             .seedSupport2No,
             .addTokenTrustline,
             .postponePushPermissionRequest,
             .givePermission:
            return .secondary
        case .openMobileFinishActivation(let needsAttention), .reduceAmountBy(_, _, let needsAttention):
            return needsAttention ? .primary : .secondary
        }
    }
}
