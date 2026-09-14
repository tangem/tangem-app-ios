//
//  EmptyTransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemStaking

/// Keeps the auxiliary data repository fully in-memory while `transactionHistoryV2` is off: the schema those tables
/// live in is not verified on production yet, so nothing must read from or write to the database behind the toggle.
/// Every consumer of the repository is itself behind the same toggle, so this costs nothing - it only guarantees
/// that a dependency reached by accident can't touch the database.
struct EmptyTransactionHistoryAuxDataStorage {}

// MARK: - TransactionHistoryAuxDataStorage protocol conformance

extension EmptyTransactionHistoryAuxDataStorage: TransactionHistoryAuxDataStorage {
    // MARK: Express providers

    func providers() async throws -> [TransactionHistoryAuxDataCachedValue<ExpressProvider>] { [] }

    func saveProviders(_ providers: [ExpressProvider]) async throws {}

    // MARK: Fiat currencies

    func fiatCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<OnrampFiatCurrency>] { [] }

    func saveFiatCurrencies(_ currencies: [OnrampFiatCurrency]) async throws {}

    // MARK: Crypto currencies

    func cryptoCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<TokenItem>] { [] }

    func saveCryptoCurrencies(_ tokenItems: [TokenItem]) async throws {}

    // MARK: Staking targets

    func stakingTargets() async throws -> [TransactionHistoryAuxDataCachedValue<StakingTargetSummary>] { [] }

    func saveStakingTargets(_ targets: [StakingTargetSummary]) async throws {}
}
