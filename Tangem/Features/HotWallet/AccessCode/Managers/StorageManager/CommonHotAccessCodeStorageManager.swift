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
    private var wrongAccessCodes: [String: [Date]] = [:]
}

// MARK: - Private methods

private extension CommonHotAccessCodeStorageManager {
    func wrongAccessCodesDates(userWalletModel: UserWalletModel) -> [Date] {
        wrongAccessCodes[userWalletModel.userWalletId.stringValue] ?? []
    }
}

// MARK: - HotAccessCodeStorageManager

extension CommonHotAccessCodeStorageManager: HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletModel: UserWalletModel) -> HotWrongAccessCodeStore {
        let dates = wrongAccessCodesDates(userWalletModel: userWalletModel)
        return HotWrongAccessCodeStore(dates: dates)
    }

    func storeWrongAccessCode(userWalletModel: UserWalletModel, date: Date) {
        var dates = wrongAccessCodesDates(userWalletModel: userWalletModel)
        dates.append(date)
        wrongAccessCodes[userWalletModel.userWalletId.stringValue] = dates
    }

    func clearWrongAccessCode(userWalletModel: UserWalletModel) {
        wrongAccessCodes.removeValue(forKey: userWalletModel.userWalletId.stringValue)
    }
}
