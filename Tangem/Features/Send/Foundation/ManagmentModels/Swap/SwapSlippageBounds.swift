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

    init?(defaultSlippage: Decimal?, isCustomSlippageSupported: Bool) {
        guard isCustomSlippageSupported, let defaultSlippage else {
            return nil
        }

        self.init(defaultSlippage: defaultSlippage)

        guard isValid else {
            return nil
        }
    }

    func accepts(_ slippage: Decimal) -> Bool {
        slippage >= minSlippage && slippage <= maxSlippage
    }

    static func normalized(_ slippage: Decimal) -> Decimal {
        slippage.rounded(scale: Constants.fractionScale, roundingMode: .plain)
    }
}

// MARK: - SwapProviderSlippage

struct SwapProviderSlippage: Equatable {
    let defaultSlippage: Decimal
    let isCustomSlippageSupported: Bool

    var customSlippageBounds: SwapSlippageBounds? {
        SwapSlippageBounds(defaultSlippage: defaultSlippage, isCustomSlippageSupported: isCustomSlippageSupported)
    }
}

// MARK: - ExpressAvailableProvider

extension ExpressAvailableProvider {
    var providerSlippage: SwapProviderSlippage? {
        defaultSlippage.map { SwapProviderSlippage(defaultSlippage: $0, isCustomSlippageSupported: provider.isCustomSlippageSupported) }
    }

    var customSlippageBounds: SwapSlippageBounds? {
        SwapSlippageBounds(defaultSlippage: defaultSlippage, isCustomSlippageSupported: provider.isCustomSlippageSupported)
    }
}

// MARK: - Constants

private extension SwapSlippageBounds {
    enum Constants {
        static let fractionScale = 4
        static let minSlippage: Decimal = 0.0001
    }
}
