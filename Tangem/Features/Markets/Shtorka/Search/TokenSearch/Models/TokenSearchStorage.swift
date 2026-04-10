//
//  TokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// TokenSearchStorage persists two small lists to local storage:
///
///   1. Hints — last 3 search query strings the user acted on (tapped a result)
///      - Saved when user taps ANY asset in search results (BF-09)
///      - Stores the current search bar text at the moment of tap
///      - FIFO: if > 3 entries, oldest removed
///      - Sorted by save time DESC
///
///   2. Recents — last 3 market asset identifiers the user navigated to
///      - Saved when user taps a MARKET asset only (user asset taps do NOT go here) (BF-10)
///      - Stores the asset's coin ID (from MarketsTokenModel.id)
///      - FIFO: if > 3 entries, oldest removed
///      - Sorted by save time DESC
///
/// Both lists are cleared together by the "Clear All" button in the Recent block.
///
/// Persistence options (choose during implementation):
///   - AppSettings (@AppStorageCompat) for simple string arrays
///   - PersistentStorage (PersistentStorageKey) for structured/encrypted data
///   See: Tangem/Features/AppSettings/AppSettings.swift
///   See: Tangem/Features/PersistentStorage/PersistentStorageKey.swift
protocol TokenSearchStorage: AnyObject {
    var hints: [String] { get }
    var recents: [String] { get }

    func saveHint(_ query: String)
    func saveRecent(assetId: String)
    func clearAll()
}
