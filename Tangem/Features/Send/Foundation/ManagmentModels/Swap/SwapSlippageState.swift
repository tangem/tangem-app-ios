//
//  SwapSlippageState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress

final class SwapSlippageState {
    private let _slippage = CurrentValueSubject<SwapSlippage, Never>(.auto)
    private let _isReset = CurrentValueSubject<Bool, Never>(false)
    private var customSlippagePair: Pair?

    var slippage: SwapSlippage {
        _slippage.value
    }

    var slippagePublisher: AnyPublisher<SwapSlippage, Never> {
        _slippage.eraseToAnyPublisher()
    }

    var isResetPublisher: AnyPublisher<Bool, Never> {
        _isReset.eraseToAnyPublisher()
    }

    @discardableResult
    func set(_ slippage: SwapSlippage, for pair: Pair?) -> Bool {
        _isReset.send(false)

        guard slippage != _slippage.value else {
            return false
        }

        _slippage.send(slippage)
        customSlippagePair = slippage == .auto ? nil : pair
        return true
    }

    func reset() {
        guard _slippage.value != .auto else {
            return
        }

        _isReset.send(true)
        _slippage.send(.auto)
        customSlippagePair = nil
    }

    func shouldReset(for state: ExpressManagerState, pair: Pair?) -> Bool {
        guard case .custom(let value) = _slippage.value else {
            return false
        }

        guard customSlippagePair == pair else {
            return true
        }

        guard case .swap(.some(let selected), _) = state else {
            return false
        }

        guard let bounds = selected.customSlippageBounds else {
            return true
        }

        return !bounds.accepts(value)
    }
}

// MARK: - Pair

extension SwapSlippageState {
    struct Pair: Equatable {
        let source: TokenItem
        let receive: TokenItem
    }
}
