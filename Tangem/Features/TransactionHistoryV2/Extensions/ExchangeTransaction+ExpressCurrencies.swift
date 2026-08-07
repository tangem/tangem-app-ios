//
//  ExchangeTransaction+ExpressCurrencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

// MARK: - Convenience extensions

extension ExchangeTransaction {
    /// Every `ExpressCurrency` referenced by this transaction.
    var expressCurrencies: [ExpressCurrency] {
        return [
            from.currency,
            to.currency,
            refund?.currency,
        ].compactMap(\.self)
    }
}
