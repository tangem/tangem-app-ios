//
//  CommonHotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

private enum HotAccessCodeStorageKey: String {
    /// Store wrong access code input events.
    case wrongAccessCode
}

final class CommonHotAccessCodeStorageManager {
    // [REDACTED_TODO_COMMENT]
    @AppStorageCompat(HotAccessCodeStorageKey.wrongAccessCode)
    private var wrongAccessCodes: [String: [TimeInterval]] = [:]
}

// MARK: - Private methods

private extension CommonHotAccessCodeStorageManager {
    func wrongAccessCodesLockIntervals(userWalletModel: UserWalletModel) -> [TimeInterval] {
        wrongAccessCodes[userWalletModel.userWalletId.stringValue] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletModel: UserWalletModel) -> HotWrongAccessCodeStore {
        let lockIntervals = wrongAccessCodesLockIntervals(userWalletModel: userWalletModel)
        return HotWrongAccessCodeStore(lockIntervals: lockIntervals)
    }

    func storeWrongAccessCode(userWalletModel: UserWalletModel, lockInterval: TimeInterval) {
        var lockIntervals = wrongAccessCodesLockIntervals(userWalletModel: userWalletModel)
        lockIntervals.append(lockInterval)
        wrongAccessCodes[userWalletModel.userWalletId.stringValue] = lockIntervals
    }

    func clearWrongAccessCode(userWalletModel: UserWalletModel) {
        wrongAccessCodes.removeValue(forKey: userWalletModel.userWalletId.stringValue)
    }
}
