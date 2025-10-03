//
//  SessionMobileAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class SessionMobileAccessCodeStorageManager {
    private var userWalletIdsWithWrongAccessCodes: [String: [TimeInterval]] = [:]

    fileprivate init() {}
}

// MARK: - Private methods

private extension SessionMobileAccessCodeStorageManager {
    func wrongAccessCodesLockIntervals(userWalletId: UserWalletId) -> [TimeInterval] {
        userWalletIdsWithWrongAccessCodes[userWalletId.stringValue] ?? []
    }
}

// MARK: - MobileAccessCodeStorageManager

extension SessionMobileAccessCodeStorageManager: MobileAccessCodeStorageManager {
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

// MARK: - Injection

private struct SessionMobileAccessCodeStorageManagerKey: InjectionKey {
    static var currentValue: MobileAccessCodeStorageManager = SessionMobileAccessCodeStorageManager()
}

extension InjectedValues {
    var sessionMobileAccessCodeStorageManager: MobileAccessCodeStorageManager {
        get { Self[SessionMobileAccessCodeStorageManagerKey.self] }
        set { Self[SessionMobileAccessCodeStorageManagerKey.self] = newValue }
    }
}
