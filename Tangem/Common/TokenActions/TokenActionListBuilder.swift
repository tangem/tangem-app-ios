//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActionsForButtonsList(canShowSwap: Bool) -> [TokenActionType] {
        var actions: [TokenActionType] = [.buy, .send, .receive, .sell]
        if canShowSwap {
            actions.append(.exchange)
        }

        return actions
    }

    func buildTokenContextActions(
        canExchange: Bool,
        canSend: Bool,
        canSwap: Bool,
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

        if canExchange, canSell {
            availableActions.append(.sell)
        }

        if canSwap {
            availableActions.append(.exchange)
        }

        availableActions.append(.hide)

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
