//
//  SwapSlippageBounds.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemExpress

struct SwapSlippageBounds {
    let defaultSlippage: Decimal

    var minSlippage: Decimal { Constants.minSlippage }
    var maxSlippage: Decimal { Self.normalized(defaultSlippage * 2) }
    var warningThreshold: Decimal { Self.normalized(defaultSlippage / 2) }

    var isValid: Bool {
        defaultSlippage >= minSlippage
    }

    init(defaultSlippage: Decimal) {
        self.defaultSlippage = Self.normalized(defaultSlippage)
    }

    func accepts(_ slippage: Decimal) -> Bool {
        slippage >= minSlippage && slippage <= maxSlippage
    }

    static func normalized(_ slippage: Decimal) -> Decimal {
        slippage.rounded(scale: Constants.fractionScale, roundingMode: .plain)
    }
}

// MARK: - ExpressProvider

extension ExpressProvider {
    var customSlippageBounds: SwapSlippageBounds? {
        guard isCustomSlippageSupported, let slippage else {
            return nil
        }

        let bounds = SwapSlippageBounds(defaultSlippage: slippage)
        return bounds.isValid ? bounds : nil
    }
}

// MARK: - Constants

private extension SwapSlippageBounds {
    enum Constants {
        static let fractionScale = 4
        static let minSlippage: Decimal = 0.0001
    }
}
