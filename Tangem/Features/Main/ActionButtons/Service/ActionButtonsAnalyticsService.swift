//
//  ActionButtonsAnalyticsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum ActionButtonsAnalyticsService {
    static func trackCloseButtonTap(source: CloseSource) {
        Analytics.log(event: .actionButtonsButtonClose, params: [Analytics.ParameterKey.source: source.rawValue])
    }

    static func trackActionButtonTap(button: ActionButtonModel, state: ActionButtonState) {
        let event: Analytics.Event = switch button {
        case .buy: .mainScreenButtonAddFunds
        case .swap: .actionButtonsSwapButton
        // In the redesign the `.sell` button is labeled "Transfer" and opens the transfer method screen.
        case .sell: FeatureProvider.isAvailable(.redesign) ? .mainScreenButtonTransfer : .actionButtonsSellButton
        }

        let status: ActionButtonStatus = switch state {
        case .initial, .loading: .pending
        case .idle: .success
        case .restricted, .disabled, .unavailable: .error
        }

        Analytics.log(event: event, params: [.status: status.rawValue])
    }

    static func trackScreenOpened(_ screenModel: ActionButtonModel) {
        switch screenModel {
        case .buy:
            Analytics.log(.addFundsMethodScreenOpened, params: [.source: .main])
        case .swap:
            Analytics.log(.actionButtonsSwapScreenOpened)
        case .sell:
            Analytics.log(.actionButtonsSellScreenOpened)
        }
    }

    static func trackTokenClicked(_ screenModel: ActionButtonModel, tokenSymbol: String) {
        let event: Analytics.Event = switch screenModel {
        case .buy: .actionButtonsBuyTokenClicked
        case .swap: .actionButtonsSwapTokenClicked
        case .sell: .actionButtonsSellTokenClicked
        }

        Analytics.log(event: event, params: [.token: tokenSymbol])
    }

    static func trackReceiveTokenClicked(tokenSymbol: String) {
        Analytics.log(event: .actionButtonsReceiveTokenClicked, params: [.token: tokenSymbol])
    }

    static func removeButtonClicked(tokenSymbol: String) {
        Analytics.log(event: .actionButtonsRemoveButtonClicked, params: [.token: tokenSymbol])
    }

    static func hotTokenClicked(tokenSymbol: String) {
        Analytics.log(event: .actionButtonsHotTokenClicked, params: [.token: tokenSymbol])
    }

    static func hotTokenError(errorCode: String) {
        Analytics.log(event: .actionButtonsHotTokenError, params: [.errorCode: errorCode])
    }
}

extension ActionButtonsAnalyticsService {
    enum CloseSource: String {
        case buy = "Buy"
        case sell = "Sell"
        case swap = "Swap"
    }

    enum ActionButtonStatus: String {
        case success = "Success"
        case pending = "Pending"
        case error = "Error"
    }
}
