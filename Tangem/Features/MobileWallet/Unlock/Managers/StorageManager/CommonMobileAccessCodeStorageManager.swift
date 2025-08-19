//
//  CommonMobileAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonMobileAccessCodeStorageManager {
    @AppStorageCompat(MobileAccessCodeStorageKey.wrongAccessCode)
    private var userWalletIdsWithWrongAccessCodes: [String: [TimeInterval]] = [:]
}

// MARK: - Private methods

private extension CommonMobileAccessCodeStorageManager {
    func wrongAccessCodesLockIntervals(userWalletId: UserWalletId) -> [TimeInterval] {
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] ?? []
    }
}

// MARK: - MobileAccessCodeStorageManager

extension CommonMobileAccessCodeStorageManager: MobileAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> MobileWrongAccessCodeStore {
        let lockIntervals = wrongAccessCodesLockIntervals(userWalletId: userWalletId)
        return MobileWrongAccessCodeStore(lockIntervals: lockIntervals)
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

private enum MobileAccessCodeStorageKey: String {
    /// Store wrong access code input events.
    case wrongAccessCode
}
