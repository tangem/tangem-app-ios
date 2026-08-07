//
//  OnrampTransaction+ExpressCurrencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

// MARK: - Convenience extensions

extension OnrampTransaction {
    /// Every `ExpressCurrency` referenced by this transaction.
    var expressCurrencies: [ExpressCurrency] {
        return [
            to.currency,
        ]
    }
}
