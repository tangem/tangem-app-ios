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
    case buyCrypto(currencySymbol: String?)
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case leaveAmount(amount: Decimal, amountFormatted: String)
    case reduceAmountBy(amount: Decimal, amountFormatted: String)
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
    case openReferralProgram
    case openMobileFinishActivation(needsAttention: Bool)
    case openMobileUpgrade
    case openYieldPromo
    case openBuyCrypto(walletModel: any WalletModel, parameters: PredefinedOnrampParameters)
    case tangemPayCreateAccountAndIssueCard
    case tangemPayViewKYCStatus
    case allowPushPermissionRequest
    case postponePushPermissionRequest

    var id: Int {
        switch self {
        case .generateAddresses: "generateAddresses".hashValue
        case .backupCard: "backupCard".hashValue
        case .buyCrypto(let currencySymbol): "buyCrypto\(String(describing: currencySymbol))".hashValue
        case .openFeeCurrency(let currencySymbol): "openFeeCurrency\(currencySymbol)".hashValue
        case .refresh: "refresh".hashValue
        case .refreshFee: "refresh_fee".hashValue
        case .goToProvider: "goToProvider".hashValue
        case .leaveAmount(let amount, let amountFormatted): "leaveAmount\(amount)\(amountFormatted)".hashValue
        case .reduceAmountBy(let amount, let amountFormatted): "reduceAmountBy\(amount)\(amountFormatted)".hashValue
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
        case .openReferralProgram: "openReferralProgram".hashValue
        case .openMobileFinishActivation(let needsAttention): "openMobileFinishActivation\(needsAttention)".hashValue
        case .openMobileUpgrade: "openMobileUpgrade".hashValue
        case .openYieldPromo: "openYieldPromo".hashValue
        case .openBuyCrypto(let walletModel, let parameters): "openBuyCrypto\(walletModel.id)\(parameters.hashValue)".hashValue
        case .tangemPayCreateAccountAndIssueCard: "tangemPayCreateAccountAndIssueCard".hashValue
        case .tangemPayViewKYCStatus: "tangemPayViewKYCStatus".hashValue
        case .allowPushPermissionRequest: "allowPushPermissionRequest".hashValue
        case .postponePushPermissionRequest: "postponePushPermissionRequest".hashValue
        }
    }

    var title: String {
        switch self {
        case .generateAddresses:
            return Localization.commonGenerateAddresses
        case .backupCard:
            return Localization.buttonStartBackupProcess
        case .buyCrypto(let currencySymbol):
            guard let currencySymbol else {
                // [REDACTED_TODO_COMMENT]
                return "Top up card"
            }
            return Localization.commonBuyCurrency(currencySymbol)
        case .openFeeCurrency(let currencySymbol):
            return Localization.commonBuyCurrency(currencySymbol)
        case .refresh, .refreshFee:
            return Localization.warningButtonRefresh
        case .goToProvider:
            return Localization.commonGoToProvider
        case .reduceAmountBy(_, let amountFormatted):
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
            return Localization.detailsRowTitleContactToSupport
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
        case .openReferralProgram:
            return Localization.referralButtonParticipate
        case .addTokenTrustline:
            return Localization.warningTokenTrustlineButtonTitle
        case .openMobileFinishActivation:
            return Localization.hwActivationNeedFinish
        case .openMobileUpgrade:
            return .empty
        case .openYieldPromo:
            return Localization.commonGetStarted
        case .openBuyCrypto:
            return Localization.commonBuy
        case .tangemPayCreateAccountAndIssueCard:
            return Localization.commonContinue
        case .tangemPayViewKYCStatus:
            // [REDACTED_TODO_COMMENT]
            return "View Status"
        case .allowPushPermissionRequest:
            return Localization.commonEnable
        case .postponePushPermissionRequest:
            return Localization.commonLater
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses,
             .retryKaspaTokenTransaction,
             .unlock:
            return .trailing(Assets.tangemIcon)
        case .swap:
            return .leading(Assets.exchangeMini)
        case .backupCard,
             .buyCrypto,
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
             .openReferralProgram,
             .addTokenTrustline,
             .openMobileFinishActivation,
             .openMobileUpgrade,
             .openYieldPromo,
             .openBuyCrypto,
             .tangemPayCreateAccountAndIssueCard,
             .tangemPayViewKYCStatus,
             .allowPushPermissionRequest,
             .postponePushPermissionRequest:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .openLink,
             .openAppStoreReview,
             .empty,
             .unlock,
             .openMobileUpgrade,
             .allowPushPermissionRequest:
            return .primary
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .support,
             .stake,
             .openFeedbackMail,
             .openCurrency,
             .swap,
             .seedSupportNo,
             .seedSupportYes,
             .seedSupport2Yes,
             .seedSupport2No,
             .openReferralProgram,
             .addTokenTrustline,
             .openYieldPromo,
             .openBuyCrypto,
             .tangemPayCreateAccountAndIssueCard,
             .tangemPayViewKYCStatus,
             .postponePushPermissionRequest:
            return .secondary
        case .openMobileFinishActivation(let needsAttention):
            return needsAttention ? .primary : .secondary
        }
    }
}
