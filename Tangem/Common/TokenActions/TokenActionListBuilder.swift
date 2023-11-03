//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActionsForButtonsList(canShowBuySell: Bool, canShowSwap: Bool) -> [TokenActionType] {
        var actions: [TokenActionType] = []
        if canShowBuySell {
            actions.append(.buy)
        }

        actions.append(contentsOf: [.send, .receive])

        if canShowBuySell {
            actions.append(.sell)
        }

        if canShowSwap {
            actions.append(.exchange)
        }

        return actions
    }

    func buildTokenContextActions(
        canExchange: Bool,
        canSend: Bool,
        canSwap: Bool,
        canHide: Bool,
        isBlockchainReachable: Bool,
        exchangeUtility: ExchangeCryptoUtility
    ) -> [TokenActionType] {
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.copyAddress]
        if canExchange, canBuy {
            availableActions.append(.buy)
        }

        if canSend {
            availableActions.append(.send)
        }

        availableActions.append(.receive)

        if isBlockchainReachable, canExchange, canSell {
            availableActions.append(.sell)
        }

        if isBlockchainReachable, canSwap {
            availableActions.append(.exchange)
        }

        if canHide {
            availableActions.append(.hide)
        }

        return availableActions
    }

    func buildActionsForLockedSingleWallet() -> [TokenActionType] {
        [
            .buy,
            .send,
            .receive,
            .sell,
        ]
    }
}
