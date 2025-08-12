//
//  CommonHotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonHotAccessCodeStorageManager {
    @AppStorageCompat(HotAccessCodeStorageKey.wrongAccessCode)
    private var userWalletIdsWithWrongAccessCodes: [String: [TimeInterval]] = [:]
}

// MARK: - Private methods

private extension CommonHotAccessCodeStorageManager {
    func wrongAccessCodesLockIntervals(userWalletId: UserWalletId) -> [TimeInterval] {
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> HotWrongAccessCodeStore {
        let lockIntervals = wrongAccessCodesLockIntervals(userWalletId: userWalletId)
        return HotWrongAccessCodeStore(lockIntervals: lockIntervals)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, lockInterval: TimeInterval) {
        var lockIntervals = wrongAccessCodesLockIntervals(userWalletId: userWalletId)
        lockIntervals.append(lockInterval)
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] = lockIntervals
    }

    func removeWrongAccessCode(userWalletId: UserWalletId) {
        userWalletIdsWithWrongAccessCodes.removeValue(forKey: userWalletId.stringValue)
    }
}

// MARK: - StorageKey

private enum HotAccessCodeStorageKey: String {
    /// Store wrong access code input events.
    case wrongAccessCode
}
