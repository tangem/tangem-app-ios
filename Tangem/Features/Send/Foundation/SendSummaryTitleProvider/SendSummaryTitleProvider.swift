//
//  SendSummaryTitleProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

protocol SendSummaryTitleProvider {
    var title: String { get }
}

// MARK: - Send

struct CommonSendSummaryTitleProvider: SendSummaryTitleProvider {
    let tokenItem: TokenItem
    let walletName: String

    var title: String {
        switch tokenItem.token?.metadata.kind {
        case .nonFungible:
            Localization.sendSummaryTitle(Localization.commonNft)
        default:
            Localization.sendSummaryTitle(tokenItem.currencySymbol)
        }
    }
}

// MARK: - Sell

struct SellSendSummaryTitleProvider: SendSummaryTitleProvider {
    var title: String { Localization.commonSell }
}

// MARK: - Send with Swap

struct SendWithSwapSummaryTitleProvider: SendSummaryTitleProvider {
    weak var receiveTokenInput: SendReceiveTokenInput?

    var title: String {
        switch receiveTokenInput?.receiveToken {
        case .none, .same:
            Localization.commonSend
        case .swap:
            Localization.sendWithSwapTitle
        }
    }
}

// MARK: - Staking

struct StakingSendSummaryTitleProvider: SendSummaryTitleProvider {
    let actionType: SendFlowActionType
    let tokenItem: TokenItem
    let walletName: String

    var title: String {
        switch actionType {
        case .approve, .stake:
            return "\(Localization.commonStake) \(tokenItem.currencySymbol)"
        case .claimUnstaked:
            return SendFlowActionType.withdraw.title
        default:
            return actionType.title
        }
    }
}

// MARK: - Onramp

struct OnrampSendSummaryTitleProvider: SendSummaryTitleProvider {
    let tokenItem: TokenItem

    var title: String {
        "\(Localization.commonBuy) \(tokenItem.name)"
    }
}
