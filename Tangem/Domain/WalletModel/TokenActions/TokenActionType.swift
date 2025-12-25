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
import TangemMacro

@RawCaseName
enum TokenActionType {
    case buy
    case send
    case receive
    case exchange
    case stake
    case sell
    case copyAddress
    case marketsDetails
    case hide
    case yield(apy: String)

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
        case .yield: return Localization.commonYieldMode
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
        case .yield: return Assets.YieldModule.yieldSupplyAssets
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
        case .yield(let apy): return Localization.yieldModuleMainScreenPromoBannerMessage(apy)
        }
    }

    var analyticsParameterValue: String {
        rawCaseValue.capitalizingFirstLetter()
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
        case .copyAddress, .hide, .stake, .marketsDetails, .yield:
            return nil
        }
    }
}

extension TokenActionType: Identifiable, Hashable {
    var id: String {
        let suffix: String = switch self {
        case .yield(let apy): apy
        default: .empty
        }

        return rawCaseValue + suffix
    }
}
