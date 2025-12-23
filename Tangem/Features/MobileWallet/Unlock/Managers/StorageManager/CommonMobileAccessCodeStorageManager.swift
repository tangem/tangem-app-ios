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
    private let secureEnclave = SecureEnclaveService()

    private func fetch(userWalletId: UserWalletId) throws -> [TimeInterval] {
        let key = MobileAccessCodeStorageKey.wrongAccessCode(userWalletId: userWalletId)
        let seKey = MobileAccessCodeStorageKey.wrongAccessCodeSEKeyTag(userWalletId: userWalletId)

        if let encryptedData = try secureStorage.get(key) {
            let encodedData = try secureEnclave.decryptData(encryptedData, keyTag: seKey)
            return try JSONDecoder().decode([TimeInterval].self, from: encodedData)
        }

        return []
    }

    private func save(userWalletId: UserWalletId, lockIntervals: [TimeInterval]) {
        let key = MobileAccessCodeStorageKey.wrongAccessCode(userWalletId: userWalletId)
        let seKey = MobileAccessCodeStorageKey.wrongAccessCodeSEKeyTag(userWalletId: userWalletId)

        do {
            let data = try JSONEncoder().encode(lockIntervals)
            let encryptedData = try secureEnclave.encryptData(data, keyTag: seKey)
            try secureStorage.store(encryptedData, forKey: key)
        } catch {
            AppLogger.error("Failed to save wrong access code storage", error: error)
        }
    }
}

// MARK: - MobileAccessCodeStorageManager

extension CommonMobileAccessCodeStorageManager: MobileAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) throws -> MobileWrongAccessCodeStore {
        let lockIntervals = try fetch(userWalletId: userWalletId)
        return MobileWrongAccessCodeStore(lockIntervals: lockIntervals)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, lockInterval: TimeInterval, replaceLast: Bool) {
        do {
            var lockIntervals = try fetch(userWalletId: userWalletId)
            if replaceLast { _ = lockIntervals.popLast() }
            lockIntervals.append(lockInterval)
            save(userWalletId: userWalletId, lockIntervals: lockIntervals)
        } catch {
            AppLogger.error("Failed to storeWrongAccessCode", error: error)
        }
    }

    func removeWrongAccessCode(userWalletId: UserWalletId) {
        save(userWalletId: userWalletId, lockIntervals: [])
    }
}

// MARK: - StorageKey

private enum MobileAccessCodeStorageKey {
    /// Store wrong access code input events.
    static func wrongAccessCode(userWalletId: UserWalletId) -> String {
        return "wrongAccessCode_\(userWalletId.stringValue)"
    }

    /// Secure enclave encryption key
    static func wrongAccessCodeSEKeyTag(userWalletId: UserWalletId) -> String {
        return "wrongAccessCodeSEKeyTag_\(userWalletId.stringValue)"
    }
}
