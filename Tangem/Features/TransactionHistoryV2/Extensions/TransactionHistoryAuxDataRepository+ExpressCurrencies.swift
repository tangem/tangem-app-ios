//
//  TransactionHistoryAuxDataRepository+Convenience.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

// MARK: - Convenience extensions

extension TransactionHistoryAuxDataRepository {
    nonisolated func cryptoCurrencies(for currencies: [ExpressCurrency]) -> [ExpressCurrency: TokenItem] {
        return currencies.reduce(into: [:]) { result, currency in
            result[currency] = cryptoCurrency(for: currency)
        }
    }
}
