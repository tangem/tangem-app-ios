//
//  TokenSearchResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// [STUB] Delete this comment when implemented.
///
/// TokenSearchResult holds aggregated results for rendering:
///   - userAssets: sorted by balance DESC
///   - marketAssets: sorted by market cap DESC (from existing MarketsListDataProvider API)
///   - isUserAssetsCollapsed: true when > 3 results, "Show more" button visible
///   - isHiddenBalancesMode: if true, all user asset balances show placeholder
struct TokenSearchResult: Equatable {
    let userAssets: [UserAssetSearchResult]
    let groupedUserAssets: [GroupedUserAssetResult]
    let isUserAssetsCollapsed: Bool
    let isHiddenBalancesMode: Bool

    /// [STUB] Delete this property when implemented — replace with [MarketsTokenModel].
    let marketAssets: [String]
}
