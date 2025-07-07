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
    typealias UserWalletId = String

    @AppStorageCompat(HotAccessCodeStorageKey.wrongAccessCode)
    private var wrongAccessCodes: [UserWalletId: [Date]] = [:]
}

// MARK: - Private methods

private extension CommonHotAccessCodeStorageManager {
    func wrongAccessCodesDates(userWalletId: UserWalletId) -> [Date] {
        wrongAccessCodes[userWalletId] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> HotWrongAccessCodeStore {
        let dates = wrongAccessCodesDates(userWalletId: userWalletId)
        return HotWrongAccessCodeStore(dates: dates)
    }

    func storeWrongAccessCode(userWalletId: UserWalletId, date: Date) {
        var dates = wrongAccessCodesDates(userWalletId: userWalletId)
        dates.append(date)
        wrongAccessCodes[userWalletId] = dates
    }

    func clearWrongAccessCode(userWalletId: UserWalletId) {
        wrongAccessCodes.removeValue(forKey: userWalletId)
    }

    func clearWrongAccessCode() {
        wrongAccessCodes.removeAll()
    }
}
