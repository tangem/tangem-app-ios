//
//  ScannedCardWalletUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemFoundation

class ScannedCardWalletUnlocker: UserWalletModelUnlocker {
    var canUnlockAutomatically: Bool { false }

    var canShowUnlockUIAutomatically: Bool { false }

    private let userWalletId: UserWalletId
    private let encryptionKey: UserWalletEncryptionKey

    init(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey) {
        self.userWalletId = userWalletId
        self.encryptionKey = encryptionKey
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        return UserWalletModelUnlockerResult.success(userWalletId: userWalletId, encryptionKey: encryptionKey)
    }
}
