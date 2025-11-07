//
//  TokenActionType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

enum TokenActionType: String {
    case buy
    case send
    case receive
    case exchange
    case stake
    case sell
    case copyAddress
    case marketsDetails
    case hide

    var title: String {
        switch self {
        case .buy: return Localization.commonBuy
        case .send: return Localization.commonSend
        case .receive: return Localization.commonReceive
        case .exchange: return Localization.swappingSwapAction
        case .stake: return Localization.commonStake
        case .sell: return Localization.commonSell
        case .copyAddress: return Localization.commonCopyAddress
        case .marketsDetails: return Localization.commonAnalytics
        case .hide: return Localization.tokenDetailsHideToken
        }
    }

    var icon: ImageType {
        switch self {
        case .buy: return Assets.plusMini
        case .send: return Assets.arrowUpMini
        case .receive: return Assets.arrowDownMini
        case .exchange: return Assets.exchangeMini
        case .stake: return Assets.stakingIcon
        case .sell: return Assets.dollarMini
        case .copyAddress: return Assets.Glyphs.copy
        case .marketsDetails: return Assets.chartMini20
        case .hide: return Assets.minusCircle
        }
    }

    var isDestructive: Bool {
        switch self {
        case .hide: return true
        default: return false
        }
    }

    var description: String? {
        switch self {
        case .buy: return Localization.buyTokenDescription
        case .send: return nil
        case .receive: return Localization.receiveTokenDescription
        case .exchange: return Localization.exchangeTokenDescription
        case .stake: return Localization.stakeTokenDescription
        case .sell: return nil
        case .copyAddress: return nil
        case .marketsDetails: return nil
        case .hide: return nil
        }
    }

    var analyticsParameterValue: String {
        rawValue.capitalizingFirstLetter()
    }

    var accessibilityIdentifier: String? {
        switch self {
        case .buy:
            return ActionButtonsAccessibilityIdentifiers.buyButton
        case .send:
            return ActionButtonsAccessibilityIdentifiers.sendButton
        case .receive:
            return ActionButtonsAccessibilityIdentifiers.receiveButton
        case .exchange:
            return ActionButtonsAccessibilityIdentifiers.swapButton
        case .sell:
            return ActionButtonsAccessibilityIdentifiers.sellButton
        case .copyAddress, .hide, .stake, .marketsDetails:
            return nil
        }
    }
}

extension TokenActionType: CaseIterable, Identifiable {
    var id: String { rawValue }
}
