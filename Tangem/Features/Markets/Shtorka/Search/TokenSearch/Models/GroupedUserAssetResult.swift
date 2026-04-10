//
//  GroupedUserAssetResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// [STUB] Delete this comment when implemented.
///
/// GroupedUserAssetResult merges multiple UserAssetSearchResults into one row:
///   - iconStackCount: min(assets.count, 3) — drives stacked icon layers (see BF-03)
///   - Tap action: opens a Bottom Sheet with Wallet → Account → Network → Asset hierarchy (BF-04)
///   - totalBalance: sum of all loaded balances in the group
struct GroupedUserAssetResult: Identifiable {
    let id: String
    let displayName: String
    let ticker: String
    let assets: [UserAssetSearchResult]

    var iconStackCount: Int {
        min(assets.count, 3)
    }
}
