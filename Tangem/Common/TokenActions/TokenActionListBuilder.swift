//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    func buildActions(for cardModel: CardViewModel, exchangeUtility: ExchangeCryptoUtility) -> [TokenActionType] {
        let canExchange = cardModel.canExchangeCrypto
        let canBuy = exchangeUtility.buyAvailable
        let canSell = exchangeUtility.sellAvailable

        var availableActions: [TokenActionType] = [.send, .receive]

        if canExchange {
            if canBuy {
                availableActions.insert(.buy, at: 0)
            }
            if canSell {
                availableActions.append(.sell)
            }
        }

        return availableActions
    }
}
