//
//  UserAssetsSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// UserAssetsSearchProvider performs synchronous (< 100ms) local search across the user's portfolio.
///
/// Search scope:
///   - ALL accounts in ALL active (unlocked) wallets
///   - Matches query string against token name AND ticker (case-insensitive substring match)
///   - See: BF-02 for search rules
///
/// Data access chain:
///   UserWalletRepository → [UserWalletModel] → AccountModelsManager → WalletModels
///   Use AccountWalletModelsAggregator.walletModels(from:) to extract all WalletModel instances
///   See: Tangem/Domain/Accounts/Utils/AccountWalletModelsAggregator.swift
///
/// Grouping (when multiple wallets/accounts exist):
///   - System tokens: group by TokenItem.id match
///   - Custom tokens (no id): group by name + ticker match
///   - Grouping triggers when > 1 variant of same asset found
///   - See: BF-03 + US-13 for grouping rules
///
/// Filtering:
///   - Skip locked wallets (UserWalletModel.isUserWalletLocked)
///   - Include all account types
protocol UserAssetsSearchProviding {
    func search(query: String) -> [UserAssetSearchResult]
}
