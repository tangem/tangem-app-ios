//
//  CommonOnrampStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct CommonOnrampStorage: OnrampStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let key: PersistentStorageKey

    init(key: PersistentStorageKey = .onrampPreference) {
        self.key = key
    }

    func save(preference: OnrampUserPreference) {
        do {
            try storage.store(value: preference, for: key)
        } catch {
            ExpressLogger.error("Failed to save changes in storage", error: error)
        }
    }

    func preference() -> OnrampUserPreference? {
        do {
            return try storage.value(for: key)
        } catch {
            ExpressLogger.error("Couldn't get the staking transactions list from the storage", error: error)
            return nil
        }
    }
}
