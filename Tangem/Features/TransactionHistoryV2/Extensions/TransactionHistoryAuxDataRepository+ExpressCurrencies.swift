//
//  TransactionHistoryAuxDataRepository+ExpressCurrencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

// MARK: - Convenience extensions

extension TransactionHistoryAuxDataRepository {
    /// Resolves against every supported blockchain (`SupportedBlockchains.all`) — the most permissive scope.
    /// A single Express transaction can reference currencies the current wallet doesn't support: e.g. a swap of
    /// token A in wallet 1 to token B in wallet 2, where wallet 1's config lacks token B's blockchain.
    /// This overload covers exactly that case.
    nonisolated func cryptoCurrency(for currency: ExpressCurrency) -> TokenItem? {
        return cryptoCurrency(for: currency, supportedBlockchains: SupportedBlockchains.all)
    }

    /// Resolves against every supported blockchain (`SupportedBlockchains.all`) — the most permissive scope.
    /// A single Express transaction can reference currencies the current wallet doesn't support: e.g. a swap of
    /// token A in wallet 1 to token B in wallet 2, where wallet 1's config lacks token B's blockchain.
    /// This overload covers exactly that case.
    func cryptoCurrency(for currency: ExpressCurrency) async -> TokenItem? {
        return await cryptoCurrency(for: currency, supportedBlockchains: SupportedBlockchains.all)
    }

    nonisolated func cryptoCurrencies(for currencies: [ExpressCurrency]) -> [ExpressCurrency: TokenItem] {
        return currencies.reduce(into: [:]) { result, currency in
            result[currency] = cryptoCurrency(for: currency)
        }
    }
}
