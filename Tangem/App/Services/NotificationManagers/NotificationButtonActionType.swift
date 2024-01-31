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
    case goToProvider
    case exchange

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
        case .refresh:
            return Localization.warningButtonRefresh
        case .goToProvider:
            return Localization.commonGoToProvider
        case .exchange:
            return Localization.tokenSwapPromotionButton
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses:
            return .trailing(Assets.tangemIcon)
        case .exchange:
            return .leading(Assets.exchangeMini)
        case .backupCard, .buyCrypto, .openFeeCurrency, .refresh, .goToProvider:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses:
            return .primary
        case .backupCard, .buyCrypto, .openFeeCurrency, .refresh, .goToProvider:
            return .secondary
        case .exchange:
            return .exchangePromotionWhite
        }
    }
}
