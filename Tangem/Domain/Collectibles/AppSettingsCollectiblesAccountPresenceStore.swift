//
//  AppSettingsCollectiblesAccountPresenceStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AppSettingsCollectiblesAccountPresenceStore {
    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }
}

// MARK: - CollectiblesAccountPresenceStore protocol conformance

extension AppSettingsCollectiblesAccountPresenceStore: CollectiblesAccountPresenceStore {
    func contains(_ userWalletId: UserWalletId) -> Bool {
        settings.collectiblesHasAccount[key(for: userWalletId), default: false]
    }

    func insert(_ userWalletId: UserWalletId) {
        guard !contains(userWalletId) else {
            return
        }

        settings.collectiblesHasAccount[key(for: userWalletId)] = true
    }

    func remove(_ userWalletId: UserWalletId) {
        guard contains(userWalletId) else {
            return
        }

        settings.collectiblesHasAccount[key(for: userWalletId)] = nil
    }
}

// MARK: - Private implementation

private extension AppSettingsCollectiblesAccountPresenceStore {
    /// The wallet id is private, so the settings hold a hash of it rather than the id itself.
    func key(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.collectiblesHasAccount.rawValue)
    }
}
