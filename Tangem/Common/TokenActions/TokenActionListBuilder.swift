//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActionsForButtonsList() -> [TokenActionType] {
        return [.buy, .send, .receive, .sell, .exchange]
    }

    func buildTokenContextActions(
        canExchange: Bool,
        exchangeUtility: ExchangeCryptoUtility,
        canHide: Bool
    ) -> [TokenActionType] {
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.copyAddress, .send, .receive]

        if canExchange {
            if canBuy {
                availableActions.insert(.buy, at: 0)
            }
            if canSell {
                availableActions.append(.sell)
            }
        }

        if canHide {
            availableActions.append(.hide)
        }

        return availableActions
    }
}
