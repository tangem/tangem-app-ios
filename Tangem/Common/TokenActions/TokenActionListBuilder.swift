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

        actions.append(contentsOf: [.receive, .send])

        if canShowSwap {
            actions.append(.exchange)
        }

        if canShowBuySell {
            actions.append(.buy)
        }

        if canShowBuySell {
            actions.append(.sell)
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

        availableActions.append(.receive)

        if canSend {
            availableActions.append(.send)
        }

        if isBlockchainReachable, canSwap {
            availableActions.append(.exchange)
        }

        // [REDACTED_TODO_COMMENT]
        if canExchange, canBuy {
            availableActions.append(.buy)
        }

        if isBlockchainReachable, canExchange, canSell {
            availableActions.append(.sell)
        }

        if canHide {
            availableActions.append(.hide)
        }

        return availableActions
    }

    func buildActionsForLockedSingleWallet() -> [TokenActionType] {
        [
            .receive,
            .send,
            .buy,
            .sell,
        ]
    }
}
