//
//  PolymarketOrderGate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemPolymarketUI

struct PolymarketOrderGate {
    let notifications: [PolymarketOrderNotification]
    let amountCaption: AmountCaption?
    let isPrimaryButtonEnabled: Bool

    init(state: PolymarketOrderModel.State, intent: PolymarketOrderIntent) {
        let required = switch intent {
        case .buy: state.quote.quote?.total ?? state.enteredAmount
        case .sell: state.enteredAmount
        }

        let hasSufficientBalance = required.map { required in
            state.balance.map { $0 >= required } ?? false
        } ?? false

        notifications = Self.notifications(state: state, intent: intent)
        amountCaption = Self.amountCaption(state: state, intent: intent, required: required)

        isPrimaryButtonEnabled = notifications.allSatisfy { !$0.isBlocking }
            && Self.isQuotePlaceable(state: state, intent: intent)
            && !state.isBelowMinAmount
            && hasSufficientBalance
            && state.geoblock == .allowed
    }
}

// MARK: - Amount caption

extension PolymarketOrderGate {
    enum AmountCaption: Hashable {
        case toWin(expected: Decimal, guaranteed: Decimal)
        case belowMinAmount(Decimal)
        case notEnoughForBet
        case notEnoughForFees
        case notEnoughLiquidity
    }
}

// MARK: - Private implementation

private extension PolymarketOrderGate {
    static func isQuotePlaceable(state: PolymarketOrderModel.State, intent: PolymarketOrderIntent) -> Bool {
        guard let status = state.quote.quote?.status else { return false }

        if case .sell = intent, status == .belowMinOrderSize {
            return true
        }

        return status == .belowMinOrderAmount || status.isPlaceable
    }

    static func notifications(state: PolymarketOrderModel.State, intent: PolymarketOrderIntent) -> [PolymarketOrderNotification] {
        var notifications: [PolymarketOrderNotification] = []

        switch state.quote {
        case .content(let quote):
            switch quote.status {
            case .partial: notifications.append(.partialFill)
            case .belowMinOrderSize:
                if case .buy = intent, !state.isBelowMinAmount {
                    notifications.append(.belowMinOrder)
                }
            case .full, .belowMinOrderAmount, .insufficientLiquidity, .marketClosed, .undefined: break
            }
        case .unavailable(let unavailability):
            switch unavailability {
            case .insufficientLiquidity:
                if case .buy = intent {
                    notifications.append(.noLiquidity)
                }
            case .marketClosed: notifications.append(.marketClosed)
            case .undefined: notifications.append(.quoteUnavailable)
            }
        case .failed, .empty, .loading:
            break
        }

        if state.geoblock == .blocked {
            notifications.append(.regionRestricted)
        }

        return notifications
    }

    static func amountCaption(
        state: PolymarketOrderModel.State,
        intent: PolymarketOrderIntent,
        required: Decimal?
    ) -> AmountCaption? {
        if case .sell = intent, case .unavailable(.insufficientLiquidity) = state.quote {
            return .notEnoughLiquidity
        }

        if state.isBelowMinAmount, let minAmount = state.minAmount {
            return .belowMinAmount(minAmount)
        }

        if let balance = state.balance, let entered = state.enteredAmount, entered > balance {
            return .notEnoughForBet
        }

        if case .buy = intent, let balance = state.balance, let required, required > balance {
            return .notEnoughForFees
        }

        guard let quote = state.quote.quote else { return nil }

        switch intent {
        case .buy:
            return .toWin(expected: quote.expectedExecutionAmount, guaranteed: quote.shares)
        case .sell:
            return nil
        }
    }
}
