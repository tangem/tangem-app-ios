//
//  AppDatabaseTableKind.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A type representing a kind of the database table, which can be registered in the database.
enum AppDatabaseTableKind: CaseIterable {
    case expressProvidersCacheTable
    case fiatCurrenciesCacheTable
    case cryptoCurrenciesCacheTable
    case expressExchangeTransactionsTable
    case expressOnrampTransactionsTable
    case expressSyncMetadataTable

    var table: AppDatabaseTable.Type {
        switch self {
        case .expressProvidersCacheTable:
            ExpressProvidersCacheTable.self
        case .fiatCurrenciesCacheTable:
            FiatCurrenciesCacheTable.self
        case .cryptoCurrenciesCacheTable:
            CryptoCurrenciesCacheTable.self
        case .expressExchangeTransactionsTable:
            ExpressExchangeTransactionsTable.self
        case .expressOnrampTransactionsTable:
            ExpressOnrampTransactionsTable.self
        case .expressSyncMetadataTable:
            ExpressSyncMetadataTable.self
        }
    }
}
