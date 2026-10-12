//
//  CommonFeedSearchHistoryStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct CommonFeedSearchHistoryStorage: FeedSearchHistoryStorage {
    private let storage = CachesDirectoryStorage(file: .cachedFeedSearchHistory)

    func load() -> StoredFeedSearchHistory? {
        try? storage.value()
    }

    func save(_ history: StoredFeedSearchHistory) {
        storage.store(value: history) { error in
            if let error {
                AppLogger.error(error: error)
            }
        }
    }
}
