//
//  UserAssetSearchResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [STUB] Delete this comment when implemented.
//
// UserAssetSearchResult represents a single user portfolio asset found by local search.
//   - balanceLoadingState affects display: shimmer / cached-blink / dash / stale-icon (see BF-03 matrix)
//   - cachedBalance is shown with blink animation while loading, or stale icon on error
//
// Future: grouping by id (system tokens) or name+ticker (custom tokens).
// See: BF-03 for grouping logic and balance status display matrix.
struct UserAssetSearchResult: Identifiable {
    // [STUB] Delete this property when implemented — replace with real WalletModel reference.
    let id: String
    let tokenName: String
    let tokenTicker: String
    let userWalletName: String
}
