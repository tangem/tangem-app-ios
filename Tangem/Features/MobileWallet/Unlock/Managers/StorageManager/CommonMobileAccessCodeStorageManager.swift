//
//  CommonMobileAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

final class CommonMobileAccessCodeStorageManager {
    private let secureStorage = SecureStorage()

    private func fetch() -> [String: [TimeInterval]] {
        do {
            let data = try secureStorage.get(MobileAccessCodeStorageKey.wrongAccessCode) ?? Data()
            return try JSONDecoder().decode([String: [TimeInterval]].self, from: data)
        } catch {
            AppLogger.error("Failed to get wrong access code storage", error: error)
            return [:]
        }
    }

    private func save(lockIntervals: [String: [TimeInterval]]) {
        do {
            let data = try JSONEncoder().encode(lockIntervals)
            try secureStorage.store(data, forKey: MobileAccessCodeStorageKey.wrongAccessCode)
        } catch {
            AppLogger.error("Failed to save wrong access code storage", error: error)
        }
    }
}

// MARK: - MobileAccessCodeStorageManager

extension CommonMobileAccessCodeStorageManager: MobileAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> MobileWrongAccessCodeStore {
        let allLockIntervals = fetch()
        let lockIntervals = allLockIntervals[userWalletId.stringValue] ?? []
        return MobileWrongAccessCodeStore(lockIntervals: lockIntervals)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, lockInterval: TimeInterval) {
        var allLockIntervals = fetch()
        var lockIntervals = allLockIntervals[userWalletId.stringValue] ?? []
        lockIntervals.append(lockInterval)
        allLockIntervals[userWalletId.stringValue] = lockIntervals
        save(lockIntervals: allLockIntervals)
    }

    func removeWrongAccessCode(userWalletId: UserWalletId) {
        var allLockIntervals = fetch()
        allLockIntervals[userWalletId.stringValue] = nil
        save(lockIntervals: allLockIntervals)
    }
}

// MARK: - StorageKey

private enum MobileAccessCodeStorageKey {
    /// Store wrong access code input events.
    static let wrongAccessCode = "wrongAccessCode"
}
