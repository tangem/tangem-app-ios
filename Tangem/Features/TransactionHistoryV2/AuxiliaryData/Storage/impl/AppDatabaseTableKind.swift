//
//  AppDatabaseTableKind.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AppDatabaseTableKind: CaseIterable {
    case expressProvidersCache
    case fiatCurrenciesCache

    var table: AppDatabaseTable.Type {
        switch self {
        case .expressProvidersCache:
            ExpressProvidersCacheTable.self
        case .fiatCurrenciesCache:
            FiatCurrenciesCacheTable.self
        }
    }
}
