//
//  CommonTransactionHistoryAuxDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB
import TangemExpress
import TangemFoundation
import TangemAppDatabase

struct CommonTransactionHistoryAuxDataStorage {
    @Injected(\.appDatabase) private var appDatabase: AppDatabase
}

// MARK: - TransactionHistoryAuxDataStorage protocol conformance

extension CommonTransactionHistoryAuxDataStorage: TransactionHistoryAuxDataStorage {
    // MARK: Express providers

    func providers() async throws -> [TransactionHistoryAuxDataCachedValue<ExpressProvider>] {
        return try await appDatabase.databaseHandle.read { database in
            return try ExpressProviderRecord
                .fetchAll(database)
                .compactMap { record in
                    do {
                        let provider = try TransactionHistoryAuxDataMapper.mapToExpressProvider(record)

                        return TransactionHistoryAuxDataCachedValue(value: provider, updatedAt: record.updatedAt)
                    } catch {
                        // A single malformed record shouldn't prevent the entire list from being returned,
                        // therefore only log the error w/o throwing it
                        TransactionHistoryLogger.warning("Skipping malformed express provider row \(record.id): \(error)")
                        return nil
                    }
                }
        }
    }

    func saveProviders(_ providers: [ExpressProvider]) async throws {
        try await appDatabase.databaseHandle.write { database in
            let updatedAt = Date()

            let records = providers
                .map { provider in
                    TransactionHistoryAuxDataMapper.mapToExpressProviderRecord(provider, updatedAt: updatedAt)
                }

            let expressProvidersToKeepFilter = records
                .grouped(by: \.type)
                .map { type, records in
                    ExpressProviderRecord.Columns.type == type && records.map(\.id).contains(ExpressProviderRecord.Columns.id)
                }
                .joined(operator: .or) // Logical OR since each provider can match any of the `type + id` combinations

            // Database housekeeping: delete records that are not present in the new list of providers
            try ExpressProviderRecord
                .filter(!expressProvidersToKeepFilter)
                .deleteAll(database)

            for record in records {
                try record.upsert(database)
            }
        }
    }

    // MARK: Fiat currencies

    func fiatCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<OnrampFiatCurrency>] {
        return try await appDatabase.databaseHandle.read { database in
            return try FiatCurrencyRecord
                .fetchAll(database)
                .compactMap { record in
                    do {
                        let currency = try TransactionHistoryAuxDataMapper.mapToOnrampFiatCurrency(record)

                        return TransactionHistoryAuxDataCachedValue(value: currency, updatedAt: record.updatedAt)
                    } catch {
                        // A single malformed record shouldn't prevent the entire list from being returned,
                        // therefore only log the error w/o throwing it
                        TransactionHistoryLogger.warning("Skipping malformed fiat currency row \(record.id): \(error)")
                        return nil
                    }
                }
        }
    }

    func saveFiatCurrencies(_ currencies: [OnrampFiatCurrency]) async throws {
        try await appDatabase.databaseHandle.write { database in
            let updatedAt = Date()

            let records = currencies
                .map { currency in
                    TransactionHistoryAuxDataMapper.mapToFiatCurrencyRecord(currency, updatedAt: updatedAt)
                }

            let fiatCurrenciesToKeepIDs = records
                .map(\.code)

            // Database housekeeping: delete records that are not present in the new list of fiat currencies
            try FiatCurrencyRecord
                .filter(!fiatCurrenciesToKeepIDs.contains(FiatCurrencyRecord.Columns.code))
                .deleteAll(database)

            for record in records {
                try record.upsert(database)
            }
        }
    }

    // MARK: Crypto currencies

    func cryptoCurrencies() async throws -> [TransactionHistoryAuxDataCachedValue<TokenItem>] {
        return try await appDatabase.databaseHandle.read { database in
            return try CryptoCurrencyRecord
                .fetchAll(database)
                .compactMap { record in
                    do {
                        let tokenItem = try TransactionHistoryAuxDataMapper.mapToTokenItem(record)

                        return TransactionHistoryAuxDataCachedValue(value: tokenItem, updatedAt: record.updatedAt)
                    } catch {
                        // A single malformed record shouldn't prevent the entire list from being returned,
                        // therefore only log the error w/o throwing it
                        TransactionHistoryLogger.warning("Skipping malformed crypto currency row \(record.networkID): \(error)")
                        return nil
                    }
                }
        }
    }

    func saveCryptoCurrencies(_ tokenItems: [TokenItem]) async throws {
        try await appDatabase.databaseHandle.write { database in
            let updatedAt = Date()
            let records = tokenItems
                .compactMap { tokenItem -> CryptoCurrencyRecord? in
                    do {
                        return try TransactionHistoryAuxDataMapper.mapToCryptoCurrencyRecord(tokenItem, updatedAt: updatedAt)
                    } catch {
                        // A single unsupported token item shouldn't prevent the entire list from being saved,
                        // therefore only log the error w/o throwing it
                        TransactionHistoryLogger.warning("Skipping token item: \(error)")
                        return nil
                    }
                }

            // [REDACTED_TODO_COMMENT]
            for record in records {
                try record.upsert(database)
            }
        }
    }
}
