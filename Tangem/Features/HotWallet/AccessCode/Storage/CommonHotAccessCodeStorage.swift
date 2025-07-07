//
//  CommonHotAccessCodeStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonHotAccessCodeStorage {
    // [REDACTED_TODO_COMMENT]
    typealias UserWalletId = String

    private let userWalletId: UserWalletId
    private let manager: HotAccessCodeStorageManager

    init(userWalletId: UserWalletId, manager: HotAccessCodeStorageManager) {
        self.userWalletId = userWalletId
        self.manager = manager
    }
}

// MARK: - HotAccessCodeStorage

extension CommonHotAccessCodeStorage: HotAccessCodeStorage {
    func getWrongAccessCodeStore() -> HotWrongAccessCodeStore {
        manager.getWrongAccessCodeStore(userWalletId: userWalletId)
    }

    func storeWrongAccessCodeAttempt(date: Date) {
        manager.storeWrongAccessCode(userWalletId: userWalletId, date: date)
    }

    func clearWrongAccessCodeStore() {
        manager.clearWrongAccessCode(userWalletId: userWalletId)
    }
}
