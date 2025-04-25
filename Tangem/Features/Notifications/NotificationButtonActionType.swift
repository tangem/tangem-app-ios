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

struct NotificationButtonAction {
    let type: NotificationButtonActionType
    let withLoader: Bool

    init(_ type: NotificationButtonActionType, withLoader: Bool = false) {
        self.type = type
        self.withLoader = withLoader
    }
}

enum NotificationButtonActionType: Identifiable, Hashable {
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
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
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

    var id: Int { hashValue }

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
             .openReferralProgram:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .openLink,
             .openAppStoreReview,
             .empty,
             .unlock:
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
             .openReferralProgram:
            return .secondary
        }
    }
}
