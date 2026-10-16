//
//  PolymarketAccountPresenceStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PolymarketAccountPresenceStore {
    func hasAccount(userWalletId: UserWalletId) -> Bool
    func markAccountExists(for userWalletId: UserWalletId)

    func hadPositions(userWalletId: UserWalletId) -> Bool
    func markPositionsExisted(for userWalletId: UserWalletId)

    func delete(userWalletId: UserWalletId)
}

// MARK: - AppSettings

extension AppSettings: PolymarketAccountPresenceStore {
    func hasAccount(userWalletId: UserWalletId) -> Bool {
        polymarketHasAccount[accountKey(for: userWalletId), default: false]
    }

    func markAccountExists(for userWalletId: UserWalletId) {
        polymarketHasAccount[accountKey(for: userWalletId)] = true
    }

    func hadPositions(userWalletId: UserWalletId) -> Bool {
        polymarketHadPositions[positionsKey(for: userWalletId), default: false]
    }

    func markPositionsExisted(for userWalletId: UserWalletId) {
        polymarketHadPositions[positionsKey(for: userWalletId)] = true
    }

    func delete(userWalletId: UserWalletId) {
        polymarketHasAccount[accountKey(for: userWalletId)] = nil
        polymarketHadPositions[positionsKey(for: userWalletId)] = nil
    }
}

// MARK: - Private implementation

private extension AppSettings {
    func accountKey(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.polymarketHasAccount.rawValue)
    }

    func positionsKey(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.polymarketHadPositions.rawValue)
    }
}
