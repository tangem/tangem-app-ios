//
//  CachesDirectoryStorage.File+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension CachesDirectoryStorage.File where Self == CachesDirectoryFile {
    static var cachedBalances: Self { CachesDirectoryFile.cachedBalancesFile }
    static var cachedQuotes: Self { CachesDirectoryFile.cachedQuotesFile }
    static var cachedExpressAvailability: Self { CachesDirectoryFile.cachedExpressAvailabilityFile }
}

enum CachesDirectoryFile: CachesDirectoryStorage.File {
    case cachedBalancesFile
    case cachedQuotesFile
    case cachedExpressAvailabilityFile

    var name: String {
        switch self {
        case .cachedBalancesFile:
            return "cached_balances"
        case .cachedQuotesFile:
            return "cached_quotes"
        case .cachedExpressAvailabilityFile:
            return "cached_express_availability"
        }
    }
}
