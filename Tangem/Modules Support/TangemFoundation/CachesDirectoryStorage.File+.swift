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

    static func cachedNFTAssets(userWalletIdStringValue: String) -> Self {
        return .cachedNFTAssetsFile(userWalletIdStringValue: userWalletIdStringValue)
    }

    static var cachedYieldMarkets: Self { CachesDirectoryFile.cachedYieldMarketsFile }
    static var cachedYieldModuleState: Self { CachesDirectoryFile.cachedYieldModuleStateFile }
    static var cachedStakingManagerState: Self { CachesDirectoryFile.cachedStakingManagerStateFile }
}

enum CachesDirectoryFile: CachesDirectoryStorage.File {
    case cachedBalancesFile
    case cachedQuotesFile
    case cachedExpressAvailabilityFile
    case cachedNFTAssetsFile(userWalletIdStringValue: String)
    case cachedYieldMarketsFile
    case cachedYieldModuleStateFile
    case cachedStakingManagerStateFile

    var name: String {
        switch self {
        case .cachedBalancesFile:
            return "cached_balances"
        case .cachedQuotesFile:
            return "cached_quotes"
        case .cachedExpressAvailabilityFile:
            return "cached_express_availability"
        case .cachedNFTAssetsFile(let userWalletIdStringValue):
            return "nft_assets_cache_\(userWalletIdStringValue)"
        case .cachedYieldMarketsFile:
            return "cached_yield_markets"
        case .cachedYieldModuleStateFile:
            return "cached_yield_module_state"
        case .cachedStakingManagerStateFile:
            return "cached_staking_manager_state"
        }
    }
}
