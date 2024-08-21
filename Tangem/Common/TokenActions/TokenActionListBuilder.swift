//
//  TokenActionListBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenActionListBuilder {
    /// Uses for decide visibility on the hotizontal action buttons list on `TokenDetails/SingleWalletMain`
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

    /// Uses for decide visibility on the long tap menu action buttons list on `TokenItemView`
    func buildTokenContextActions(
        canExchange: Bool,
        canSignTransactions: Bool,
        canSend: Bool,
        canSwap: Bool,
        canStake: Bool,
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

        if canSignTransactions, isBlockchainReachable, canSwap {
            availableActions.append(.exchange)
        }

        if canSignTransactions, isBlockchainReachable, canStake {
            availableActions.append(.stake)
        }

        // [REDACTED_TODO_COMMENT]
        if canExchange, canBuy {
            availableActions.append(.buy)
        }

        if canSend, canExchange, canSell {
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
