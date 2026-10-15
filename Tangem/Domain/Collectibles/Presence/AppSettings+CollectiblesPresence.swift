//
//  AppSettings+CollectiblesPresence.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemCollectibles

extension AppSettings: CollectiblesPresenceStorage {}

extension StoredCollectiblesAccountPresenceStore {
    static func appSettings() -> Self {
        Self(storage: AppSettings.shared, hashSalt: StorageType.collectiblesHasAccount.rawValue)
    }
}
