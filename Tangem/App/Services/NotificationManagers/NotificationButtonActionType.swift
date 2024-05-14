//
//  NotificationButtonActionType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NotificationButtonActionType: Identifiable, Hashable {
    case generateAddresses
    case backupCard
    case buyCrypto(currencySymbol: String?)
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case exchange
    case reduceAmountBy(amount: Decimal, amountFormatted: String)
    case reduceAmountTo(amount: Decimal, amountFormatted: String)
    case bookNow(promotionLink: URL)
    case addHederaTokenAssociation
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case addTokenTrustline

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
        case .exchange:
            return Localization.tokenSwapPromotionButton
        case .reduceAmountBy(_, let amountFormatted):
            return Localization.sendNotificationReduceBy(amountFormatted)
        case .reduceAmountTo(_, let amountFormatted):
            return Localization.sendNotificationReduceTo(amountFormatted)
        case .bookNow:
            return Localization.mainTravalaPromotionButton
        case .addHederaTokenAssociation:
            return Localization.warningHederaMissingTokenAssociationButtonTitle
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses:
            return .trailing(Assets.tangemIcon)
        case .exchange:
            return .leading(Assets.exchangeMini)
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses, .bookNow:
            return .primary
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation:
            return .secondary
        case .exchange:
            return .exchangePromotionWhite
        }
    }
}
